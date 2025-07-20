// internal/api/api.go
package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jottavia/ships-go/internal/store"
)

const (
	actorAPIUser = "api-user"
)

// API wraps the store and registers handlers.
type API struct{ st *store.Store }

// RotateRequest represents the JSON payload for password rotation.
type RotateRequest struct {
	Hostname string `json:"host" binding:"required"`
	Password string `json:"password" binding:"required"`
	Actor    string `json:"actor"`
}

// UpdateKeyRequest represents the JSON payload for BitLocker key updates.
type UpdateKeyRequest struct {
	Hostname string `json:"host" binding:"required"`
	Key      string `json:"key" binding:"required"`
	Actor    string `json:"actor"`
}

// New creates a new API handler.
func New(st *store.Store) *API {
	return &API{st: st}
}

// Register registers the API routes.
func (a *API) Register(r *gin.Engine) {
	v1 := r.Group("/api/v1")
	v1.GET("/password/:host", a.getPassword)
	v1.POST("/rotate", a.rotate)
	v1.GET("/bde/:host", a.getBDEKey)
	v1.POST("/update_key", a.updateKey)
}

// getRemoteAddr extracts the remote address from the request.
func getRemoteAddr(c *gin.Context) string {
	// Check for X-Forwarded-For header first (proxy)
	if xff := c.GetHeader("X-Forwarded-For"); xff != "" {
		return xff
	}
	// Check for X-Real-IP header (nginx)
	if xri := c.GetHeader("X-Real-IP"); xri != "" {
		return xri
	}
	// Fall back to RemoteAddr
	return c.Request.RemoteAddr
}

func (a *API) getPassword(c *gin.Context) {
	hostname := c.Param("host")
	actor := c.GetHeader("X-Actor") // Allow override via header
	if actor == "" {
		actor = actorAPIUser
	}
	remoteAddr := getRemoteAddr(c)

	pwInfo, err := a.st.GetPassword(c.Request.Context(), hostname, actor, remoteAddr)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, pwInfo)
}

func (a *API) rotate(c *gin.Context) {
	var req RotateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Actor == "" {
		req.Actor = actorAPIUser
	}
	remoteAddr := getRemoteAddr(c)

	if err := a.st.RotatePassword(c.Request.Context(), req.Hostname, req.Password, req.Actor, remoteAddr); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":   "rotated",
		"hostname": req.Hostname,
		"actor":    req.Actor,
	})
}

func (a *API) getBDEKey(c *gin.Context) {
	hostname := c.Param("host")
	actor := c.GetHeader("X-Actor") // Allow override via header
	if actor == "" {
		actor = actorAPIUser
	}
	remoteAddr := getRemoteAddr(c)

	keyInfo, err := a.st.GetBDEKey(c.Request.Context(), hostname, actor, remoteAddr)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, keyInfo)
}

func (a *API) updateKey(c *gin.Context) {
	var req UpdateKeyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Actor == "" {
		req.Actor = actorAPIUser
	}
	remoteAddr := getRemoteAddr(c)

	if err := a.st.UpdateBDEKey(c.Request.Context(), req.Hostname, req.Key, req.Actor, remoteAddr); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"status":   "key stored",
		"hostname": req.Hostname,
		"actor":    req.Actor,
	})
}
