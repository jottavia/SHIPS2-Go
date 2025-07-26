// cmd/client/main.go
// shipsc is the command‑line client for the SHIPS2-Go password escrow service.
//
// Usage examples:
//   shipsc fetch   HOSTNAME
//   shipsc rotate  HOSTNAME NEWPASSWORD [-actor name]
//   shipsc bde     HOSTNAME
//   shipsc update-key HOSTNAME 48-DIGIT-KEY [-actor name]
//
// The server URL defaults to http://localhost:8080 but can be overridden
// with the environment variable SHIPS_SERVER.
package main

import (
	"bytes"
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
	if len(os.Args) < 2 {
		usageAndExit("missing command")
	}

	command := os.Args[1]
	args := os.Args[2:]

	// Handle version command
	if command == "version" || command == "--version" || command == "-v" {
		fmt.Printf("shipsc %s\n", version)
		return
	}

	server := getServerURL()

	if err := dispatchCommand(server, command, args); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

// getServerURL returns the server URL from environment or default
func getServerURL() string {
	server := os.Getenv("SHIPS_SERVER")
	if server == "" {
		server = defaultServer
	}
	// guarantee no trailing slash
	return strings.TrimRight(server, "/")
}

// dispatchCommand handles command routing to reduce main function complexity
func dispatchCommand(server, command string, args []string) error {
	switch command {
	case "fetch":
		return cmdFetch(server, args)
	case "rotate":
		return cmdRotate(server, args)
	case "bde":
		return cmdBDE(server, args)
	case "update-key", "update_key":
		return cmdUpdateKey(server, args)
	case "help", "-h", "--help":
		usageAndExit("")
		return nil
	default:
		usageAndExit("unknown command: %s", command)
		return nil
	}
}

func usageAndExit(format string, arguments ...interface{}) {
	if format != "" {
		fmt.Fprintf(os.Stderr, format+"\n\n", arguments...)
	}
	fmt.Fprintf(os.Stderr, "SHIPS2-Go client usage:\n")
	fmt.Fprintf(os.Stderr, "  shipsc fetch HOSTNAME\n")
	fmt.Fprintf(os.Stderr, "  shipsc rotate HOSTNAME NEWPASSWORD [-actor name]\n")
	fmt.Fprintf(os.Stderr, "  shipsc bde HOSTNAME\n")
	fmt.Fprintf(os.Stderr,
		"  shipsc update-key HOSTNAME 48-DIGIT-KEY [-actor name]\n")
	fmt.Fprintf(os.Stderr, "  shipsc version\n")
	fmt.Fprintf(os.Stderr, "\nEnv vars:\n")
	fmt.Fprintf(os.Stderr,
		"  SHIPS_SERVER   server base URL (default %s)\n", defaultServer)
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
	if err := httpGetJSON(url, &resp); err != nil {
		return err
	}

	fmt.Printf("Password:   %s\n", resp.Password)
	fmt.Printf("RotatedAt:  %s\n", resp.RotatedAt.Format(time.RFC3339))
	fmt.Printf("Actor:      %s\n", resp.Actor)
	return nil
}

// cmdRotate POSTs a rotation payload.
func cmdRotate(server string, args []string) error {
	flagSet := flag.NewFlagSet("rotate", flag.ContinueOnError)
	actor := flagSet.String("actor", "manual", "who performed the rotation")
	if err := flagSet.Parse(args); err != nil {
		return err
	}
	rest := flagSet.Args()
	if len(rest) != 2 {
		return errors.New("usage: shipsc rotate HOSTNAME NEWPASSWORD [-actor name]")
	}
	hostname, password := rest[0], rest[1]

	payload := map[string]string{
		"host":     hostname,
		"password": password,
		"actor":    *actor,
	}
	// Marshal the payload and propagate any error.
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal rotation payload: %w", err)
	}
	url := fmt.Sprintf("%s/api/v1/rotate", server)
	return httpPost(url, body)
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
	if err := httpGetJSON(url, &resp); err != nil {
		return err
	}

	fmt.Printf("Key:        %s\n", resp.Key)
	fmt.Printf("UpdatedAt:  %s\n", resp.UpdatedAt.Format(time.RFC3339))
	fmt.Printf("Actor:      %s\n", resp.Actor)
	return nil
}

// cmdUpdateKey POSTs a new BitLocker key.
func cmdUpdateKey(server string, args []string) error {
	flagSet := flag.NewFlagSet("update-key", flag.ContinueOnError)
	actor := flagSet.String("actor", "manual", "who provided the key")
	if err := flagSet.Parse(args); err != nil {
		return err
	}
	rest := flagSet.Args()
	if len(rest) != 2 {
		return errors.New(
			"usage: shipsc update-key HOSTNAME 48-DIGIT-KEY [-actor name]")
	}
	hostname, key := rest[0], rest[1]

	payload := map[string]string{
		"host":  hostname,
		"key":   key,
		"actor": *actor,
	}
	// Marshal the payload and propagate any error.
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal update-key payload: %w", err)
	}
	url := fmt.Sprintf("%s/api/v1/update_key", server)
	return httpPost(url, body)
}

//--------------------------------------------------------------------------
// Helpers
//--------------------------------------------------------------------------

func httpGetJSON(url string, responseStruct interface{}) error {
	client := &http.Client{Timeout: 30 * time.Second}
	// #nosec G107 – server is trusted / controlled
	resp, err := client.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		data, readErr := io.ReadAll(resp.Body)
		if readErr != nil {
			return fmt.Errorf("server %s: failed to read error body: %w",
				resp.Status, readErr)
		}
		return fmt.Errorf("server %s: %s",
			resp.Status, strings.TrimSpace(string(data)))
	}
	return json.NewDecoder(resp.Body).Decode(responseStruct)
}

func httpPost(url string, body []byte) error {
	client := &http.Client{Timeout: 30 * time.Second}
	// #nosec G107
	resp, err := client.Post(url, "application/json", bytes.NewReader(body))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		data, readErr := io.ReadAll(resp.Body)
		if readErr != nil {
			return fmt.Errorf("server %s: failed to read error body: %w",
				resp.Status, readErr)
		}
		return fmt.Errorf("server %s: %s",
			resp.Status, strings.TrimSpace(string(data)))
	}

	// Print the success JSON for scripting convenience.
	io.Copy(os.Stdout, resp.Body) // nolint:errcheck
	fmt.Println()                 // Add newline for better formatting
	return nil
}
