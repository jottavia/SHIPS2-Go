// internal/api/api.go
package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jottavia/SHIPS2-Go/internal/store"
)

type API struct{ storeInstance *store.Store }

// defaultAPIActor is used when the client does not specify an actor.
const defaultAPIActor = "api-user"

// RotateRequest represents the JSON payload for password rotation
type RotateRequest struct {
	Hostname string `json:"host" binding:"required"`
	Password string `json:"password" binding:"required"`
	Actor    string `json:"actor"`
}

// UpdateKeyRequest represents the JSON payload for BitLocker key updates
type UpdateKeyRequest struct {
	Hostname string `json:"host" binding:"required"`
	Key      string `json:"key" binding:"required"`
	Actor    string `json:"actor"`
}

func New(storeInstance *store.Store) *API {
	return &API{storeInstance: storeInstance}
}

func (apiInstance *API) Register(router *gin.Engine) {
	v1 := router.Group("/api/v1")
	v1.GET("/password/:host", apiInstance.getPassword)
	v1.POST("/rotate", apiInstance.rotate)
	v1.GET("/bde/:host", apiInstance.getBDEKey)
	v1.POST("/update_key", apiInstance.updateKey)
}

// getRemoteAddr extracts the remote address from the request
func getRemoteAddr(ctx *gin.Context) string {
	// Check for X-Forwarded-For header first (proxy)
	if xff := ctx.GetHeader("X-Forwarded-For"); xff != "" {
		return xff
	}
	// Check for X-Real-IP header (nginx)
	if xri := ctx.GetHeader("X-Real-IP"); xri != "" {
		return xri
	}
	// Fall back to RemoteAddr
	return ctx.Request.RemoteAddr
}

func (apiInstance *API) getPassword(ctx *gin.Context) {
	hostname := ctx.Param("host")
	actor := ctx.GetHeader("X-Actor") // Allow override via header
	if actor == "" {
		actor = defaultAPIActor
	}
	remoteAddr := getRemoteAddr(ctx)

	pwInfo, err := apiInstance.storeInstance.GetPassword(
		ctx.Request.Context(),
		hostname,
		actor,
		remoteAddr,
	)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, pwInfo)
}

func (apiInstance *API) rotate(ctx *gin.Context) {
	var req RotateRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Actor == "" {
		req.Actor = defaultAPIActor
	}
	remoteAddr := getRemoteAddr(ctx)

	err := apiInstance.storeInstance.RotatePassword(
		ctx.Request.Context(),
		req.Hostname,
		req.Password,
		req.Actor,
		remoteAddr,
	)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"status":   "rotated",
		"hostname": req.Hostname,
		"actor":    req.Actor,
	})
}

func (apiInstance *API) getBDEKey(ctx *gin.Context) {
	hostname := ctx.Param("host")
	actor := ctx.GetHeader("X-Actor") // Allow override via header
	if actor == "" {
		actor = defaultAPIActor
	}
	remoteAddr := getRemoteAddr(ctx)

	keyInfo, err := apiInstance.storeInstance.GetBDEKey(
		ctx.Request.Context(),
		hostname,
		actor,
		remoteAddr,
	)
	if err != nil {
		ctx.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, keyInfo)
}

func (apiInstance *API) updateKey(ctx *gin.Context) {
	var req UpdateKeyRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.Actor == "" {
		req.Actor = defaultAPIActor
	}
	remoteAddr := getRemoteAddr(ctx)

	err := apiInstance.storeInstance.UpdateBDEKey(
		ctx.Request.Context(),
		req.Hostname,
		req.Key,
		req.Actor,
		remoteAddr,
	)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"status":   "key stored",
		"hostname": req.Hostname,
		"actor":    req.Actor,
	})
}
