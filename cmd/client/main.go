// cmd/client/main.go
// shipsc is the command‑line client for the SHIPS2-Go password escrow service.
//
// Usage examples:
//
//	shipsc fetch   HOSTNAME
//	shipsc rotate  HOSTNAME NEWPASSWORD [-actor name]
//	shipsc bde     HOSTNAME
//	shipsc update-key HOSTNAME 48-DIGIT-KEY [-actor name]
//
// The server URL defaults to http://localhost:8080 but can be overridden
// with the environment variable SHIPS_SERVER.
package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

const defaultServer = "http://localhost:8080"

var version = "1.0.0" // SHIPS2-Go v1.0.0 Production Release

func main() {
	if err := run(os.Args); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) < 2 {
		usageAndExitf("missing command")
	}

	cmd := args[1]
	cmdArgs := args[2:]

	// Handle version command
	if cmd == "version" || cmd == "--version" || cmd == "-v" {
		fmt.Printf("shipsc %s\n", version)
		return nil
	}

	server := os.Getenv("SHIPS_SERVER")
	if server == "" {
		server = defaultServer
	}
	// guarantee no trailing slash
	server = strings.TrimRight(server, "/")

	switch cmd {
	case "fetch":
		return cmdFetch(server, cmdArgs)
	case "rotate":
		return cmdRotate(server, cmdArgs)
	case "bde":
		return cmdBDE(server, cmdArgs)
	case "update-key", "update_key":
		return cmdUpdateKey(server, cmdArgs)
	case "help", "-h", "--help":
		usageAndExitf("")
	default:
		usageAndExitf("unknown command: %s", cmd)
	}
	return nil
}

func usageAndExitf(format string, a ...interface{}) {
	if format != "" {
		fmt.Fprintf(os.Stderr, format+"\n\n", a...)
	}
	fmt.Fprintln(os.Stderr, "SHIPS2-Go client usage:")
	fmt.Fprintln(os.Stderr, "  shipsc fetch HOSTNAME")
	fmt.Fprintln(os.Stderr, "  shipsc rotate HOSTNAME NEWPASSWORD [-actor name]")
	fmt.Fprintln(os.Stderr, "  shipsc bde HOSTNAME")
	fmt.Fprintln(os.Stderr, "  shipsc update-key HOSTNAME 48-DIGIT-KEY [-actor name]")
	fmt.Fprintln(os.Stderr, "  shipsc version")
	fmt.Fprintln(os.Stderr, "\nEnv vars:")
	fmt.Fprintf(os.Stderr, "  SHIPS_SERVER   server base URL (default %s)\n", defaultServer)
	os.Exit(2)
}

// cmdFetch GETs /api/v1/password/:host and prints the response.
func cmdFetch(server string, args []string) error {
	if len(args) != 1 {
		return errors.New("usage: shipsc fetch HOSTNAME")
	}
	host := args[0]
	url := fmt.Sprintf("%s/api/v1/password/%s", server, host)

	var resp struct {
		Password  string    `json:"password"`
		RotatedAt time.Time `json:"rotated_at"`
		Actor     string    `json:"actor"`
	}
	if err := httpGetJSON(context.Background(), url, &resp); err != nil {
		return err
	}

	fmt.Printf("Password:   %s\n", resp.Password)
	fmt.Printf("RotatedAt:  %s\n", resp.RotatedAt.Format(time.RFC3339))
	fmt.Printf("Actor:      %s\n", resp.Actor)
	return nil
}

// cmdRotate POSTs a rotation payload.
func cmdRotate(server string, args []string) error {
	fs := flag.NewFlagSet("rotate", flag.ContinueOnError)
	actor := fs.String("actor", "manual", "who performed the rotation")
	if err := fs.Parse(args); err != nil {
		return fmt.Errorf("failed to parse flags: %w", err)
	}
	rest := fs.Args()
	if len(rest) != 2 {
		return errors.New("usage: shipsc rotate HOSTNAME NEWPASSWORD [-actor name]")
	}
	hostname, password := rest[0], rest[1]

	payload := map[string]string{
		"host":     hostname,
		"password": password,
		"actor":    *actor,
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}
	url := fmt.Sprintf("%s/api/v1/rotate", server)
	return httpPost(context.Background(), url, body)
}

// cmdBDE GETs the BitLocker key.
func cmdBDE(server string, args []string) error {
	if len(args) != 1 {
		return errors.New("usage: shipsc bde HOSTNAME")
	}
	host := args[0]
	url := fmt.Sprintf("%s/api/v1/bde/%s", server, host)

	var resp struct {
		Key       string    `json:"key"`
		UpdatedAt time.Time `json:"updated_at"`
		Actor     string    `json:"actor"`
	}
	if err := httpGetJSON(context.Background(), url, &resp); err != nil {
		return err
	}

	fmt.Printf("Key:        %s\n", resp.Key)
	fmt.Printf("UpdatedAt:  %s\n", resp.UpdatedAt.Format(time.RFC3339))
	fmt.Printf("Actor:      %s\n", resp.Actor)
	return nil
}

// cmdUpdateKey POSTs a new BitLocker key.
func cmdUpdateKey(server string, args []string) error {
	fs := flag.NewFlagSet("update-key", flag.ContinueOnError)
	actor := fs.String("actor", "manual", "who provided the key")
	if err := fs.Parse(args); err != nil {
		return fmt.Errorf("failed to parse flags: %w", err)
	}
	rest := fs.Args()
	if len(rest) != 2 {
		return errors.New("usage: shipsc update-key HOSTNAME 48-DIGIT-KEY [-actor name]")
	}
	hostname, key := rest[0], rest[1]

	payload := map[string]string{
		"host":  hostname,
		"key":   key,
		"actor": *actor,
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}
	url := fmt.Sprintf("%s/api/v1/update_key", server)
	return httpPost(context.Background(), url, body)
}

//--------------------------------------------------------------------------
// Helpers
//--------------------------------------------------------------------------

func httpGetJSON(ctx context.Context, url string, responseBody interface{}) error {
	client := &http.Client{Timeout: 30 * time.Second}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return fmt.Errorf("failed to create http request: %w", err)
	}

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("http get failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("server %s: %s", resp.Status, strings.TrimSpace(string(body)))
	}
	if err := json.NewDecoder(resp.Body).Decode(responseBody); err != nil {
		return fmt.Errorf("failed to decode json response: %w", err)
	}
	return nil
}

func httpPost(ctx context.Context, url string, body []byte) error {
	client := &http.Client{Timeout: 30 * time.Second}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("failed to create http request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("http post failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		data, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("server %s: %s", resp.Status, strings.TrimSpace(string(data)))
	}

	// Print the success JSON for scripting convenience.
	if _, err := io.Copy(os.Stdout, resp.Body); err != nil {
		return fmt.Errorf("failed to write response to stdout: %w", err)
	}
	fmt.Println() // Add newline for better formatting
	return nil
}
