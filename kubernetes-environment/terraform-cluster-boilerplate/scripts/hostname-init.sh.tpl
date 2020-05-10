#!/bin/bash

echo changing instance hostname to fully qualified domain name to enable cloud provider support

hostnamectl set-hostname  $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)

echo new hostname for node is: $(hostname)
