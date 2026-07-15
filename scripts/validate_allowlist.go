// Command validate_allowlist validates enterprise-allowlist.json against the
// core required structure of the MCP Server JSON Schema
// (https://static.modelcontextprotocol.io/schemas/2025-12-11/server.schema.json)
// and blocks CI on malformed JSON, missing required fields, or duplicate
// server names.
package main

import (
	"encoding/json"
	"fmt"
	"net/url"
	"os"
	"regexp"
)

const allowlistPath = "enterprise-allowlist.json"

// nameSchemaRegex mirrors the core "name" pattern of the official schema:
// a reverse-DNS style namespace followed by "/" and a package name
// (e.g. "io.github.domdomegg/airtable-mcp-server").
var nameSchemaRegex = regexp.MustCompile(`^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$`)

// versionSchemaRegex enforces a MAJOR.MINOR.PATCH semver-like version string.
var versionSchemaRegex = regexp.MustCompile(`^\d+\.\d+\.\d+`)

// Package mirrors the required core fields of schema's packages[] entries.
type Package struct {
	RegistryType string `json:"registryType"`
	Identifier   string `json:"identifier"`
}

// Repository mirrors the schema's optional repository object.
type Repository struct {
	URL string `json:"url"`
}

// Server mirrors the core required fields of the MCP server.schema.json.
type Server struct {
	Name        string      `json:"name"`
	Description string      `json:"description"`
	Version     string      `json:"version"`
	Repository  *Repository `json:"repository,omitempty"`
	Packages    []Package   `json:"packages"`
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Printf("✅ %s: all entries valid, no duplicate names.\n", allowlistPath)
}

func run() error {
	raw, err := os.ReadFile(allowlistPath)
	if err != nil {
		return fmt.Errorf("❌ cannot read %s: %w", allowlistPath, err)
	}

	var servers []Server
	if err := json.Unmarshal(raw, &servers); err != nil {
		return fmt.Errorf("❌ %s is not valid JSON (expected a top-level array of server objects): %w", allowlistPath, err)
	}

	if len(servers) == 0 {
		return fmt.Errorf("❌ %s contains zero server entries", allowlistPath)
	}

	var errs []string
	seenNames := make(map[string]int) // name -> first index seen

	for i, s := range servers {
		loc := fmt.Sprintf("servers[%d]", i)

		if s.Name == "" {
			errs = append(errs, fmt.Sprintf(`%s: missing required field "name"`, loc))
		} else if !nameSchemaRegex.MatchString(s.Name) {
			errs = append(errs, fmt.Sprintf(`%s: "name" %q does not match required namespace/name pattern`, loc, s.Name))
		}

		if s.Description == "" {
			errs = append(errs, fmt.Sprintf(`%s (%s): missing required field "description"`, loc, s.Name))
		}

		if s.Version == "" {
			errs = append(errs, fmt.Sprintf(`%s (%s): missing required field "version"`, loc, s.Name))
		} else if !versionSchemaRegex.MatchString(s.Version) {
			errs = append(errs, fmt.Sprintf(`%s (%s): "version" %q is not a valid MAJOR.MINOR.PATCH semver string`, loc, s.Name, s.Version))
		}

		if len(s.Packages) == 0 {
			errs = append(errs, fmt.Sprintf(`%s (%s): missing required non-empty "packages" array`, loc, s.Name))
		}
		for pi, p := range s.Packages {
			if p.RegistryType == "" {
				errs = append(errs, fmt.Sprintf(`%s (%s): packages[%d] missing required field "registryType"`, loc, s.Name, pi))
			}
			if p.Identifier == "" {
				errs = append(errs, fmt.Sprintf(`%s (%s): packages[%d] missing required field "identifier"`, loc, s.Name, pi))
			}
		}

		if s.Repository != nil && s.Repository.URL != "" {
			if u, err := url.ParseRequestURI(s.Repository.URL); err != nil || u.Scheme == "" || u.Host == "" {
				errs = append(errs, fmt.Sprintf(`%s (%s): repository.url %q is not a valid absolute URL`, loc, s.Name, s.Repository.URL))
			}
		}

		if s.Name != "" {
			if firstIdx, ok := seenNames[s.Name]; ok {
				errs = append(errs, fmt.Sprintf("%s: duplicate server name %q (already defined at servers[%d]) — an enterprise allowlist must pin exactly one approved version per server", loc, s.Name, firstIdx))
			} else {
				seenNames[s.Name] = i
			}
		}
	}

	if len(errs) > 0 {
		msg := fmt.Sprintf("❌ %s failed validation with %d error(s):\n", allowlistPath, len(errs))
		for _, e := range errs {
			msg += "  - " + e + "\n"
		}
		return fmt.Errorf("%s", msg)
	}

	return nil
}
