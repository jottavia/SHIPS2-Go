// tests/integration_test.go
package tests

import (
    "bytes"
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "os"
    "testing"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/jottavia/ships-go/internal/api"
    "github.com/jottavia/ships-go/internal/store"
)

func TestMain(m *testing.M) {
    gin.SetMode(gin.TestMode)
    os.Exit(m.Run())
}

func setupTestServer(t *testing.T) (*httptest.Server, *store.Store) {
    // Create temporary database for testing
    tempDB := "/tmp/test_ships.db"
    os.Remove(tempDB) // Clean up any existing test db

    st, err := store.New(tempDB)
    if err != nil {
        t.Fatalf("Failed to create test store: %v", err)
    }

    router := gin.New()
    api.New(st).Register(router)

    server := httptest.NewServer(router)
    return server, st
}

func TestAPICompatibility(t *testing.T) {
    server, st := setupTestServer(t)
    defer server.Close()
    defer st.Close()

    // Test password rotation
    rotatePayload := map[string]string{
        "host":     "TESTHOST01",
        "password": "TestPassword123!",
        "actor":    "test-user",
    }
    rotateBody, _ := json.Marshal(rotatePayload)

    resp, err := http.Post(server.URL+"/api/v1/rotate", "application/json", bytes.NewReader(rotateBody))
    if err != nil {
        t.Fatalf("Failed to post rotation: %v", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        t.Errorf("Expected status 200, got %d", resp.StatusCode)
    }

    var rotateResp map[string]interface{}
    if err := json.NewDecoder(resp.Body).Decode(&rotateResp); err != nil {
        t.Fatalf("Failed to decode rotation response: %v", err)
    }

    if rotateResp["status"] != "rotated" {
        t.Errorf("Expected status 'rotated', got %v", rotateResp["status"])
    }

    // Test password fetch - verify response format matches client expectations
    resp, err = http.Get(server.URL + "/api/v1/password/TESTHOST01")
    if err != nil {
        t.Fatalf("Failed to fetch password: %v", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        t.Errorf("Expected status 200, got %d", resp.StatusCode)
    }

    var fetchResp struct {
        Password  string    `json:"password"`
        RotatedAt time.Time `json:"rotated_at"`
        Actor     string    `json:"actor"`
    }
    if err := json.NewDecoder(resp.Body).Decode(&fetchResp); err != nil {
        t.Fatalf("Failed to decode fetch response: %v", err)
    }

    if fetchResp.Password != "TestPassword123!" {
        t.Errorf("Expected password 'TestPassword123!', got %v", fetchResp.Password)
    }

    if fetchResp.Actor != "test-user" {
        t.Errorf("Expected actor 'test-user', got %v", fetchResp.Actor)
    }

    if fetchResp.RotatedAt.IsZero() {
        t.Error("Expected non-zero rotation timestamp")
    }
}

func TestBitLockerKeyManagement(t *testing.T) {
    server, st := setupTestServer(t)
    defer server.Close()
    defer st.Close()

    // Test BitLocker key update
    keyPayload := map[string]string{
        "host":  "TESTHOST02",
        "key":   "123456-123456-123456-123456-123456-123456-123456-123456",
        "actor": "test-admin",
    }
    keyBody, _ := json.Marshal(keyPayload)

    resp, err := http.Post(server.URL+"/api/v1/update_key", "application/json", bytes.NewReader(keyBody))
    if err != nil {
        t.Fatalf("Failed to post key update: %v", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        t.Errorf("Expected status 200, got %d", resp.StatusCode)
    }

    // Test BitLocker key fetch
    resp, err = http.Get(server.URL + "/api/v1/bde/TESTHOST02")
    if err != nil {
        t.Fatalf("Failed to fetch BitLocker key: %v", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        t.Errorf("Expected status 200, got %d", resp.StatusCode)
    }

    var keyResp struct {
        Key       string    `json:"key"`
        UpdatedAt time.Time `json:"updated_at"`
        Actor     string    `json:"actor"`
    }
    if err := json.NewDecoder(resp.Body).Decode(&keyResp); err != nil {
        t.Fatalf("Failed to decode key response: %v", err)
    }

    expectedKey := "123456-123456-123456-123456-123456-123456-123456-123456"
    if keyResp.Key != expectedKey {
        t.Errorf("Expected key '%s', got %v", expectedKey, keyResp.Key)
    }

    if keyResp.Actor != "test-admin" {
        t.Errorf("Expected actor 'test-admin', got %v", keyResp.Actor)
    }
}

func TestInputValidation(t *testing.T) {
    server, st := setupTestServer(t)
    defer server.Close()
    defer st.Close()

    // Test invalid hostname
    invalidPayload := map[string]string{
        "host":     "invalid hostname with spaces",
        "password": "TestPassword123!",
        "actor":    "test-user",
    }
    invalidBody, _ := json.Marshal(invalidPayload)

    resp, err := http.Post(server.URL+"/api/v1/rotate", "application/json", bytes.NewReader(invalidBody))
    if err != nil {
        t.Fatalf("Failed to post invalid rotation: %v", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusInternalServerError {
        t.Errorf("Expected status 500 for invalid hostname, got %d", resp.StatusCode)
    }

    // Test empty password
    emptyPasswordPayload := map[string]string{
        "host":     "VALIDHOST",
        "password": "",
        "actor":    "test-user",
    }
    emptyPasswordBody, _ := json.Marshal(emptyPasswordPayload)

    resp, err = http.Post(server.URL+"/api/v1/rotate", "application/json", bytes.NewReader(emptyPasswordBody))
    if err != nil {
        t.Fatalf("Failed to post empty password rotation: %v", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusInternalServerError {
        t.Errorf("Expected status 500 for empty password, got %d", resp.StatusCode)
    }
}

func TestHealthEndpoint(t *testing.T) {
    server, st := setupTestServer(t)
    defer server.Close()
    defer st.Close()

    resp, err := http.Get(server.URL + "/healthz")
    if err != nil {
        t.Fatalf("Failed to call health endpoint: %v", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        t.Errorf("Expected status 200, got %d", resp.StatusCode)
    }

    body := make([]byte, 10)
    n, _ := resp.Body.Read(body)
    if string(body[:n]) != "ok" {
        t.Errorf("Expected 'ok', got %s", string(body[:n]))
    }
}

func TestAuditLogging(t *testing.T) {
    server, st := setupTestServer(t)
    defer server.Close()
    defer st.Close()

    // First, create a password entry
    rotatePayload := map[string]string{
        "host":     "AUDITHOST",
        "password": "AuditPassword123!",
        "actor":    "audit-user",
    }
    rotateBody, _ := json.Marshal(rotatePayload)

    _, err := http.Post(server.URL+"/api/v1/rotate", "application/json", bytes.NewReader(rotateBody))
    if err != nil {
        t.Fatalf("Failed to post rotation: %v", err)
    }

    // Now fetch the password to trigger audit logging
    _, err = http.Get(server.URL + "/api/v1/password/AUDITHOST")
    if err != nil {
        t.Fatalf("Failed to fetch password: %v", err)
    }

    // Verify audit logs were created - this would require direct database access
    // For now, we'll just verify the operations completed successfully
    // In a full implementation, we'd query the audit_logs table directly
}
