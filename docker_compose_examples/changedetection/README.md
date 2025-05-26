# Make sure to create a password once you spin up the container.



# Setup ntfy network bridge # (so changedetection can talk to ntfy)

networks:
  ntfy-network:
    external: true
    
    # This is an example of how you will send a notification. (use wireguard/tailscale IP)

ntfy://100.124.11.69:1125/amazon

    # "amazon" in this example is the subscribed topic on the client. (ntfy app on your external devices)
    
# Additionally to check previous lower prices and to have an additonal way of monitoring I recommend "keepa" application