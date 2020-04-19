FROM golang:1.13.6-alpine3.11 as base
RUN apk add --no-cache git gcc musl-dev dep make wget

# Use temporary image layer to archive binaries.
FROM base as bincache
ENV GOLANGCI_LINT_VERSION ${GOLANGCI_LINT_VERSION:-"1.24.0"}

RUN apk add --no-cache xz \
    && wget https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCI_LINT_VERSION}/golangci-lint-${GOLANGCI_LINT_VERSION}-linux-amd64.tar.gz -O - | \
	  tar -xzO golangci-lint-${GOLANGCI_LINT_VERSION}-linux-amd64/golangci-lint > /usr/local/bin/golangci-lint \
    && chmod +x /usr/local/bin/golangci-lint

FROM base
COPY --from=bincache /usr/local/bin/golangci-lint /usr/local/bin/golangci-lint

RUN apk add --no-cache bash coreutils docker openssh-client openssl
