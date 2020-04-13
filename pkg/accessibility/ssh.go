package sshbackdoor

import (
	"io/ioutil"
	"os"

	"k8s.io/klog"
)

//ForwardPublicKey writes desired public key to autorized keys
func ForwardPublicKey(pubKeyFile, authKeysFile string) error {
	klog.Info("Forwarding public key on nodes for backdoor ops")
	pubKey, err := ioutil.ReadFile(pubKeyFile)
	if err != nil {
		klog.Errorf("failed to read public key: %v", err)
		return err
	}

	klog.Info("Adding backdoor public key in authorized keys on node")
	authKeys, err := os.OpenFile(authKeysFile, os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		klog.Errorf("failed to open authorized keys file: %v", err)
		return err
	}
	defer authKeys.Close()

	_, err = authKeys.Write(pubKey)
	if err != nil {
		klog.Errorf("failed to write to authorized keys file: %v", err)
		return err
	}

	klog.Info("Backdoor public key forwarded successfully")
	return nil
}
