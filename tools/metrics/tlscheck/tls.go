package tlscheck

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"net"
	"strings"
	"time"
)

type TLSChecker struct{}

//go:generate counterfeiter -o fakes/fake_cert_checker.go . CertChecker
type CertChecker interface {
	DaysUntilExpiry(string, *tls.Config) (float64, error)
}

func (tc *TLSChecker) DaysUntilExpiry(addr string, tlsConfig *tls.Config) (float64, error) {
	cert, err := GetCertificate(addr, tlsConfig)
	if err == nil {
		return time.Until(cert.NotAfter).Hours() / 24, nil
	}

	if IsCertificateError(err) {
		return 0, nil
	}
	return 0, err
}

func GetCertificate(addr string, tlsConfig *tls.Config) (*x509.Certificate, error) {
	conn, err := tls.Dial("tcp", addr, tlsConfig)
	if err != nil {
		return nil, err
	}
	defer conn.Close()

	for _, chain := range conn.ConnectionState().VerifiedChains {
		for _, cert := range chain {
			if !cert.IsCA {
				return cert, nil
			}
		}
	}

	return nil, fmt.Errorf("no certificate found")
}

func IsCertificateError(err error) bool {
	switch v := err.(type) {
	case x509.CertificateInvalidError,
		x509.HostnameError,
		x509.SystemRootsError,
		x509.UnknownAuthorityError,
		x509.InsecureAlgorithmError:
		return true
	case *net.OpError:
		if v.Op == "remote error" && strings.Contains(err.Error(), "handshake failure") {
			return true // handshake error
		}
		return false
	default:
		return false
	}
}
