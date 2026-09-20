
Almost. Two corrections and one thing to check.

Dokploy domains. Only services with a Dokploy domain whose container port changed need an edit. That is more than dcm-web:

┌───────────────────────────────────────────────────────┬────────────────────────────────────────────┬────────────────────────────────────────────────────┐
│                        Service                        │             Domain target port             │                      Change?                       │
├───────────────────────────────────────────────────────┼────────────────────────────────────────────┼────────────────────────────────────────────────────┤
│ dcm-web                                               │ 2325 → 20100                               │ yes                                                │
├───────────────────────────────────────────────────────┼────────────────────────────────────────────┼────────────────────────────────────────────────────┤
│ flash-web                                             │ 5210 → 20300                               │ yes, it is deployed behind Traefik                 │
├───────────────────────────────────────────────────────┼────────────────────────────────────────────┼────────────────────────────────────────────────────┤
│ dcm-generator                                         │ 3310 → 20103                               │ only if it has a domain (it joins dokploy-network) │
├───────────────────────────────────────────────────────┼────────────────────────────────────────────┼────────────────────────────────────────────────────┤
│ dcm-admin backend                                     │ 8080 → 20104                               │ only if it has a domain                            │
├───────────────────────────────────────────────────────┼────────────────────────────────────────────┼────────────────────────────────────────────────────┤
│ dcm-admin frontend, play-crossle, Grafana, Prometheus │ unchanged (80 / 8080 / 3000 / 9090 inside) │ no                                                 │
├───────────────────────────────────────────────────────┼────────────────────────────────────────────┼────────────────────────────────────────────────────┤
│ hunter-web, tapit-web                                 │ not deployed yet                           │ set 20200 / 20400 when you create them             │
└───────────────────────────────────────────────────────┴────────────────────────────────────────────┴────────────────────────────────────────────────────┘

Dokploy environment variables. This is the one that can silently undo the change. The compose files now default to the new numbers, but if a Dokploy service has MYSQL_PORT=3309 or MYSQL_PORT=3308 set in its Environment tab, that value wins and the old port stays published. Check the env tabs of common-infra, crossle-infra, and crossle for MYSQL_PORT and remove it or set it to 20010 / 20110.

Firewall. Yes, opening 20101 and 20102 for the game server is the only new inbound rule. Keep 2303 and 2306 open until the legacy publishes are dropped. Nothing else needs a rule: web services enter through Traefik on 80/443, and MySQL, Redis, and metrics stay host-only. One caveat: the host nginx status vhost moved from 8080 to 20035, so if 8080 was ever allowed for that, swap the rule rather than leaving 8080 open.

Right now nothing advertises 20101/20102, so opening them only matters for your verification and for the later flip of dcm-web's advertised ports.