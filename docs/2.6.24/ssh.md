## connection slow
sudo nano /etc/ssh/sshd_config
UseDNS no

### ai
When `UseDNS` is enabled, the SSH server isn't looking for a website domain name like `google.com`. Instead, it is asking your network's DNS server for the **Reverse DNS record (PTR record)** of whatever IP address is trying to connect to it.

Because you are using port forwarding (`Port 2222` on `localhost`), the connection is coming from your host machine. Here is the exact step-by-step loop that is causing the timeout:

```
[Your Host] ---> (Connects via localhost:2222) ---> [Debian Guest]
                                                          |
                                           "Hey DNS, what is the domain 
                                            name for IP 10.0.2.2?" 
                                                          |
                                           [Network / Local DNS Server]
                                                          |
                                            (Silently drops request or hangs)
                                                          |
                                           [Debian Guest] (Waits 10-30s...)
                                                          |
                                                    *Timeout reached*
                                                          |
                                           "Okay, forget it. Enter password:"

```

#### The Breakdown:

1. **The IP it's looking up:** In a typical VirtualBox/QEMU NAT networking setup, connections coming from your host machine appear to the Debian guest as coming from the virtual gateway IP (usually `10.0.2.2` or `192.168.x.x`).
2. **The Question it asks:** The Debian server asks the network: *"What is the registered domain name for the IP address `10.0.2.2`?"*
3. **Why it hangs:** Since this is a private, local virtual network, there is no public DNS server that knows the answer. If your local router or VM hypervisor doesn't instantly reply with "I don't know," Debian will sit there and wait for a response until its internal timer expires.

By setting `UseDNS no`, you are telling the Debian SSH server: *"I don't care what the domain name of the connecting computer is, just log them in."*
