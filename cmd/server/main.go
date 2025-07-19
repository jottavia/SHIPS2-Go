package main

import (
    "context"
    "crypto/subtle"
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

// basicAuthMiddleware provides optional HTTP Basic Auth
func basicAuthMiddleware(username, password string) gin.HandlerFunc {
    return func(c *gin.Context) {
        if username == "" || password == "" {
            // No auth configured, skip
            c.Next()
            return
        }

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

// loggingMiddleware logs all requests
func loggingMiddleware() gin.HandlerFunc {
    return gin.LoggerWithConfig(gin.LoggerConfig{
        Formatter: gin.DefaultLogFormatter,
        Output:    os.Stdout,
    })
}

func main() {
    // Run in release mode to avoid debug logging.
    gin.SetMode(gin.ReleaseMode)

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
    st, err := store.New(dbPath)
    if err != nil {
        log.Fatalf("opening db: %v", err)
    }
    defer st.Close()

    // --- Build Gin router --------------------------------------------------
    r := gin.New()
    r.Use(gin.Recovery())
    r.Use(loggingMiddleware())

    // Add optional basic auth middleware
    if authUser != "" && authPass != "" {
        r.Use(basicAuthMiddleware(authUser, authPass))
    }

    // Liveness probe for systemd / Kubernetes or simple curl checks.
    r.GET("/healthz", func(c *gin.Context) {
        c.String(http.StatusOK, "ok")
    })

    // Version endpoint
    r.GET("/version", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "version": version,
            "service": "SHIPS2-Go",
            "status":  "Production Ready",
        })
    })

    // Register the version‑1 API under /api/v1/…
    api.New(st).Register(r)

    srv := &http.Server{
        Addr:         addr,
        Handler:      r,
        ReadTimeout:  10 * time.Second,
        WriteTimeout: 10 * time.Second,
        IdleTimeout:  120 * time.Second,
    }

    // --- Start the HTTP server in a goroutine -----------------------------
    go func() {
        log.Printf("SHIPS2-Go server v%s listening on %s", version, addr)
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("server error: %v", err)
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
        log.Fatalf("graceful shutdown failed: %v", err)
    }
    log.Printf("SHIPS2-Go server v%s stopped cleanly", version)
}
