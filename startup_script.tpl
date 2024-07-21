#!/bin/bash
echo "Starting auto-scaling test script..."

# Loop to run for 10 minutes
end=$((SECONDS+300))

while [ $SECONDS -lt $end ]; do
  curl -s http://${LB_IP} > /dev/null
  sleep 1
done

echo "Auto-scaling test script completed."