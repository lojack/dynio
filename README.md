# DynIO
Dynamic DNS for DigitalOcean

This is intended to be run as a cron job. My crontab looks something like this:

```
0 * * * * . ~/load_secrets.sh; ruby ~/dynio/dynio.rb domain.com subdomain >> ~/dynio.log 2>&1
```

Super simple. `load_secrets.sh` should load your token into `DIGITALOCEAN_TOKEN` environment variable. 

DigitalOcean can paginate API responses. I don't handle that kinda stuff, but maybe one day when I'm not lazy I'll do that.
