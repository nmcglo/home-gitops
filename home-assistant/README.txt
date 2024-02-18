The problem with this is that the container does not
have host network access and so device discovery
cannot be performed.

A workaround via multus addon for microk8s could work
but requires additional DHCP partitioning that I don't
want to do.

It is easier to just throw it onto a raspberry pi and call
it a day - instead of containerizing it.