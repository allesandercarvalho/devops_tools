package models

import "time"

// NetworkToolExecution represents a network tool execution
type NetworkToolExecution struct {
	ID           string      `json:"id"`
	UserID       string      `json:"user_id"`
	Tool         string      `json:"tool"` // "ping", "dig", "traceroute", "tcp", "curl", "nmap", "whois"
	Target       string      `json:"target"`
	Args         []string    `json:"args"`
	Status       string      `json:"status"` // "running", "completed", "failed"
	Output       string      `json:"output"`
	ParsedResult interface{} `json:"parsed_result,omitempty"`
	Error        string      `json:"error,omitempty"`
	StartedAt    time.Time   `json:"started_at"`
	CompletedAt  *time.Time  `json:"completed_at,omitempty"`
	DurationMs   int64       `json:"duration_ms"`
}

// PingResult represents parsed ping output
type PingResult struct {
	PacketsSent     int     `json:"packets_sent"`
	PacketsReceived int     `json:"packets_received"`
	PacketLoss      float64 `json:"packet_loss"`
	MinRTT          float64 `json:"min_rtt"`
	MaxRTT          float64 `json:"max_rtt"`
	AvgRTT          float64 `json:"avg_rtt"`
	StdDevRTT       float64 `json:"stddev_rtt"`
}

// DNSResult represents parsed DNS lookup output
type DNSResult struct {
	QueryType string   `json:"query_type"` // A, AAAA, MX, TXT, NS, CNAME, SOA
	Answers   []string `json:"answers"`
	QueryTime int      `json:"query_time_ms"`
	Server    string   `json:"server"`
}

// TracerouteResult represents parsed traceroute output
type TracerouteResult struct {
	Hops []TracerouteHop `json:"hops"`
}

type TracerouteHop struct {
	Number int     `json:"number"`
	IP     string  `json:"ip"`
	Host   string  `json:"host,omitempty"`
	RTT1   float64 `json:"rtt1"`
	RTT2   float64 `json:"rtt2"`
	RTT3   float64 `json:"rtt3"`
	AvgRTT float64 `json:"avg_rtt"`
}

// TCPPortResult represents TCP port check result
type TCPPortResult struct {
	Host   string `json:"host"`
	Port   int    `json:"port"`
	Open   bool   `json:"open"`
	TimeMs int64  `json:"time_ms"`
}

// HTTPResult represents HTTP request result
type HTTPResult struct {
	StatusCode    int                 `json:"status_code"`
	StatusText    string              `json:"status_text"`
	Headers       map[string][]string `json:"headers"`
	Body          string              `json:"body"`
	TimeMs        int64               `json:"time_ms"`
	ContentLength int64               `json:"content_length"`
}

// NmapResult represents parsed nmap output
type NmapResult struct {
	Hosts []NmapHost `json:"hosts"`
}

type NmapHost struct {
	Hostname string     `json:"hostname"`
	IP       string     `json:"ip,omitempty"`
	OS       string     `json:"os,omitempty"`
	Ports    []NmapPort `json:"ports"`
}

type NmapPort struct {
	Port    int    `json:"port"`
	State   string `json:"state"`
	Service string `json:"service"`
}

// WhoisResult represents parsed whois output
type WhoisResult struct {
	Domain      string   `json:"domain"`
	Registrar   string   `json:"registrar"`
	CreatedDate string   `json:"created_date"`
	ExpiryDate  string   `json:"expiry_date"`
	UpdatedDate string   `json:"updated_date"`
	Registrant  string   `json:"registrant"`
	NameServers []string `json:"name_servers"`
	RawData     string   `json:"raw_data"`
}

// GeoIPResult represents GeoIP lookup result
type GeoIPResult struct {
	IP           string  `json:"ip"`
	Country      string  `json:"country"`
	CountryCode  string  `json:"country_code"`
	Region       string  `json:"region"`
	City         string  `json:"city"`
	Latitude     float64 `json:"latitude"`
	Longitude    float64 `json:"longitude"`
	ISP          string  `json:"isp"`
	Organization string  `json:"organization"`
}

// TLSResult represents TLS certificate inspection result
type TLSResult struct {
	Host         string   `json:"host"`
	Port         int      `json:"port"`
	Version      string   `json:"version"`
	Cipher       string   `json:"cipher"`
	Issuer       string   `json:"issuer"`
	Subject      string   `json:"subject"`
	ValidFrom    string   `json:"valid_from"`
	ValidTo      string   `json:"valid_to"`
	DNSNames     []string `json:"dns_names"`
	IsValid      bool     `json:"is_valid"`
	DaysToExpiry int      `json:"days_to_expiry"`
}
