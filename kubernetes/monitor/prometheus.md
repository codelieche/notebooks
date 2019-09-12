## Prometheus基本介绍

**参考文档：**

- https://prometheus.io/
- https://prometheus.io/docs/introduction/overview/
- https://prometheus.io/docs/alerting/alertmanager/



### Architecture

This diagram illustrates the architecture of Prometheus and some of its ecosystem components:

![Prometheus architecture](image/architecture.png)

Prometheus scrapes metrics from instrumented jobs, either directly or via an intermediary push gateway for short-lived jobs. It stores all scraped samples locally and runs rules over this data to either aggregate and record new time series from existing data or generate alerts. [Grafana](https://grafana.com/) or other API consumers can be used to visualize the collected data.