package main

import (
	"context"
	"crypto/subtle"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jottavia/ships-go/internal/api"
	"github.com/jottavia/ships-go/internal/store"
)

var version = "1.0.0" // SHIPS2-Go v1.0.0 Production Release

func main() {
	if err := run(); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

func run() error {
	// --- Configuration via environment variables ---------------------------
	dbPath := os.Getenv("SHIPS_DB")
	if dbPath == "" {
		dbPath = "/var/lib/ships/ships.db" // sensible default
	}

	addr := os.Getenv("SHIPS_ADDR")
	if addr == "" {
		// Bind to loop‑back by default so the API is never exposed accidentally.
		addr = "127.0.0.1:8080"
	}

	// Optional HTTP Basic Auth
	authUser := os.Getenv("SHIPS_AUTH_USER")
	authPass := os.Getenv("SHIPS_AUTH_PASS")

	log.Printf("SHIPS2-Go server v%s starting", version)
	log.Printf("Database: %s", dbPath)
	log.Printf("Address: %s", addr)
	if authUser != "" {
		log.Printf("HTTP Basic Auth: enabled (user: %s)", authUser)
	} else {
		log.Printf("HTTP Basic Auth: disabled (set SHIPS_AUTH_USER/SHIPS_AUTH_PASS to enable)")
	}

	// --- Open the SQLite store -------------------------------------------
	storage, err := store.New(dbPath)
	if err != nil {
		return fmt.Errorf("opening db: %w", err)
	}
	defer storage.Close()

	// --- Build Gin router --------------------------------------------------
	router := setupRouter(storage, authUser, authPass)

	// --- Setup and run HTTP server -----------------------------------------
	srv := &http.Server{
		Addr:         addr,
		Handler:      router,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  120 * time.Second,
	}

	// --- Start the HTTP server in a goroutine -----------------------------
	go func() {
		log.Printf("SHIPS2-Go server v%s listening on %s", version, addr)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			// Cannot use log.Fatalf here as it calls os.Exit, which would prevent graceful shutdown.
			log.Printf("listen and serve error: %v", err)
		}
	}()

	// --- Graceful shutdown on SIGINT / SIGTERM ----------------------------
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop
	log.Println("shutdown signal received – terminating")

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		return fmt.Errorf("graceful shutdown failed: %w", err)
	}
	log.Printf("SHIPS2-Go server v%s stopped cleanly", version)
	return nil
}

func setupRouter(storage *store.Store, user, pass string) *gin.Engine {
	// Run in release mode to avoid debug logging.
	gin.SetMode(gin.ReleaseMode)
	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(gin.LoggerWithWriter(os.Stdout))

	// Add optional basic auth middleware
	if user != "" && pass != "" {
		router.Use(basicAuthMiddleware(user, pass))
	}

	// Liveness probe for systemd / Kubernetes or simple curl checks.
	router.GET("/healthz", func(c *gin.Context) {
		c.String(http.StatusOK, "ok")
	})

	// Version endpoint
	router.GET("/version", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"version": version,
			"service": "SHIPS2-Go",
			"status":  "Production Ready",
		})
	})

	// Register the version‑1 API under /api/v1/…
	api.New(storage).Register(router)
	return router
}

// basicAuthMiddleware provides optional HTTP Basic Auth.
func basicAuthMiddleware(username, password string) gin.HandlerFunc {
	return func(c *gin.Context) {
		user, pass, hasAuth := c.Request.BasicAuth()
		if !hasAuth {
			c.Header("WWW-Authenticate", "Basic realm=SHIPS2-Go")
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}

		// Use subtle.ConstantTimeCompare to prevent timing attacks
		userMatch := subtle.ConstantTimeCompare([]byte(user), []byte(username)) == 1
		passMatch := subtle.ConstantTimeCompare([]byte(pass), []byte(password)) == 1

		if !userMatch || !passMatch {
			c.Header("WWW-Authenticate", "Basic realm=SHIPS2-Go")
			c.AbortWithStatus(http.StatusUnauthorized)
			return
		}

		c.Next()
	}
}
