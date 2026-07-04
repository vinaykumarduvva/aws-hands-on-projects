## Security Group Design

### bastion-sg
| Direction | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 22 | TCP | My IP /32 | SSH from my PC only |
| Outbound | All | All | 0.0.0.0/0 | Default allow all |

### private-sg
| Direction | Port | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 22 | TCP | bastion-sg | SSH from bastion only |
| Outbound | All | All | 0.0.0.0/0 | Default allow all |

> Security group chaining: `private-sg` references `bastion-sg`
> as the source — not an IP range. This means only instances
> attached to `bastion-sg` can SSH into private instances.
> This is the production bastion host pattern.

---

