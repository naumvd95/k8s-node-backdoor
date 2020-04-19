package logging

import (
	"time"

	"k8s.io/klog"
)

//PackLogs collect logs in archives store in desired place
func PackLogs(from, to, archivePrefix string) error {
	klog.Info("[TODO] Starting log collector procedure")

	logsIteration := 1
	for i := 1; i < 10000; i++ {
		klog.InfoS("Getting logs from %s", from)
		time.Sleep(2 * time.Second)

		klog.InfoS("Packing as %s.%s.tar.gz", archivePrefix, logsIteration)
		logsIteration++
		time.Sleep(2 * time.Second)

		klog.InfoS("Saving as %s/%s.%s.tar.gz", to, archivePrefix, logsIteration)
		time.Sleep(60 * time.Second)
	}

	return nil
}
