# MIP ELT
This repo contains the script to push data from MIP (finance system) into Snowflake.  The script can only be executed by the management layer and certain individuals on IT.

## Requirements

* One must have access to MIP system
* One must have access to the FINANCE_SERVICE user on Snowflake
* One must have a Synapse account

## Implementation

This is a really scratch implementation just so the MIP data on Snowflake can be automated.  The automation is currently executed in Tom's personal service catalog account. The dockerfile is manually built and pushed to this [image](https://hub.docker.com/repository/docker/sagebionetworks/mip_elt/general) 

### Docker build
If you have a M1 mac, you will need to build the image using the following command:

```bash
docker buildx build --platform linux/amd64 -t sagebionetworks/mip_elt .
```

### To dos

* Potentially automate this in some other mechanism
* Clean up script
* Move this to another service catalog account
