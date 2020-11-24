## istioctl注入

> istioctl kube-inject -f simpleweb-v1-deployment.yaml

- 先准备一个Deployment

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: simpleweb-v1
    labels:
      app: simpleweb
      version: v1
    namespace: default
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: simpleweb
        version: v1
    template:
      metadata:
        labels:
          app: simpleweb
          version: v1
      spec:
        containers:
        - name: simpleweb
          image: codelieche/simpleweb:v1
          ports:
          - containerPort: 8080
            name: http
            protocol: TCP
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 30
  ```

- 执行注入：

  ```bash
  istioctl kube-inject -f simpleweb-v1-deployment.yaml > simpleweb-v1-inject-deployment.yaml
  ```

- 查看:`simpleweb-v1-inject-deployment.yaml`

  ```yaml
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    creationTimestamp: null
    labels:
      app: simpleweb
      version: v1
    name: simpleweb-v1
    namespace: default
  spec:
    replicas: 2
    selector:
      matchLabels:
        app: simpleweb
        version: v1
    strategy: {}
    template:
      metadata:
        annotations:
          prometheus.io/path: /stats/prometheus
          prometheus.io/port: "15020"
          prometheus.io/scrape: "true"
          sidecar.istio.io/interceptionMode: REDIRECT
          sidecar.istio.io/status: '{"version":"8e6e902b765af607513b28d284940ee1421e9a0d07698741693b2663c7161c11","initContainers":["istio-init"],"containers":["istio-proxy"],"volumes":["istio-envoy","istio-data","istio-podinfo","istiod-ca-cert"],"imagePullSecrets":null}'
          traffic.sidecar.istio.io/excludeInboundPorts: "15020"
          traffic.sidecar.istio.io/includeInboundPorts: "8080"
          traffic.sidecar.istio.io/includeOutboundIPRanges: '*'
        creationTimestamp: null
        labels:
          app: simpleweb
          istio.io/rev: ""
          security.istio.io/tlsMode: istio
          version: v1
      spec:
        containers:
        - image: codelieche/simpleweb:v1
          livenessProbe:
            httpGet:
              path: /app-health/simpleweb/livez
              port: 15020
            initialDelaySeconds: 10
          name: simpleweb
          ports:
          - containerPort: 8080
            name: http
            protocol: TCP
          readinessProbe:
            httpGet:
              path: /app-health/simpleweb/readyz
              port: 15020
            initialDelaySeconds: 30
          resources: {}
        - args:
          - proxy
          - sidecar
          - --domain
          - $(POD_NAMESPACE).svc.cluster.local
          - --serviceCluster
          - simpleweb.$(POD_NAMESPACE)
          - --proxyLogLevel=warning
          - --proxyComponentLogLevel=misc:error
          - --trust-domain=cluster.local
          - --concurrency
          - "2"
          env:
          - name: JWT_POLICY
            value: first-party-jwt
          - name: PILOT_CERT_PROVIDER
            value: istiod
          - name: CA_ADDR
            value: istiod.istio-system.svc:15012
          - name: POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: INSTANCE_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
          - name: SERVICE_ACCOUNT
            valueFrom:
              fieldRef:
                fieldPath: spec.serviceAccountName
          - name: HOST_IP
            valueFrom:
              fieldRef:
                fieldPath: status.hostIP
          - name: CANONICAL_SERVICE
            valueFrom:
              fieldRef:
                fieldPath: metadata.labels['service.istio.io/canonical-name']
          - name: CANONICAL_REVISION
            valueFrom:
              fieldRef:
                fieldPath: metadata.labels['service.istio.io/canonical-revision']
          - name: PROXY_CONFIG
            value: |
              {"proxyMetadata":{"DNS_AGENT":""}}
          - name: ISTIO_META_POD_PORTS
            value: |-
              [
                  {"name":"http","containerPort":8080,"protocol":"TCP"}
              ]
          - name: ISTIO_META_APP_CONTAINERS
            value: simpleweb
          - name: ISTIO_META_CLUSTER_ID
            value: Kubernetes
          - name: ISTIO_META_INTERCEPTION_MODE
            value: REDIRECT
          - name: ISTIO_META_WORKLOAD_NAME
            value: simpleweb-v1
          - name: ISTIO_META_OWNER
            value: kubernetes://apis/apps/v1/namespaces/default/deployments/simpleweb-v1
          - name: ISTIO_META_MESH_ID
            value: cluster.local
          - name: DNS_AGENT
          - name: ISTIO_KUBE_APP_PROBERS
            value: '{"/app-health/simpleweb/livez":{"httpGet":{"path":"/","port":8080}},"/app-health/simpleweb/readyz":{"httpGet":{"path":"/health","port":8080}}}'
          image: docker.io/istio/proxyv2:1.7.4
          imagePullPolicy: Always
          name: istio-proxy
          ports:
          - containerPort: 15090
            name: http-envoy-prom
            protocol: TCP
          readinessProbe:
            failureThreshold: 30
            httpGet:
              path: /healthz/ready
              port: 15021
            initialDelaySeconds: 1
            periodSeconds: 2
          resources:
            limits:
              cpu: "2"
              memory: 1Gi
            requests:
              cpu: 10m
              memory: 40Mi
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
              - ALL
            privileged: false
            readOnlyRootFilesystem: true
            runAsGroup: 1337
            runAsNonRoot: true
            runAsUser: 1337
          volumeMounts:
          - mountPath: /var/run/secrets/istio
            name: istiod-ca-cert
          - mountPath: /var/lib/istio/data
            name: istio-data
          - mountPath: /etc/istio/proxy
            name: istio-envoy
          - mountPath: /etc/istio/pod
            name: istio-podinfo
        initContainers:
        - args:
          - istio-iptables
          - -p
          - "15001"
          - -z
          - "15006"
          - -u
          - "1337"
          - -m
          - REDIRECT
          - -i
          - '*'
          - -x
          - ""
          - -b
          - '*'
          - -d
          - 15090,15021,15020
          env:
          - name: DNS_AGENT
          image: docker.io/istio/proxyv2:1.7.4
          imagePullPolicy: Always
          name: istio-init
          resources:
            limits:
              cpu: "2"
              memory: 1Gi
            requests:
              cpu: 10m
              memory: 10Mi
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              add:
              - NET_ADMIN
              - NET_RAW
              drop:
              - ALL
            privileged: false
            readOnlyRootFilesystem: false
            runAsGroup: 0
            runAsNonRoot: false
            runAsUser: 0
        securityContext:
          fsGroup: 1337
        volumes:
        - emptyDir:
            medium: Memory
          name: istio-envoy
        - emptyDir: {}
          name: istio-data
        - downwardAPI:
            items:
            - fieldRef:
                fieldPath: metadata.labels
              path: labels
            - fieldRef:
                fieldPath: metadata.annotations
              path: annotations
          name: istio-podinfo
        - configMap:
            name: istio-ca-root-cert
          name: istiod-ca-cert
  status: {}
  ---
  ```

  > 从上面的文件中可看到`Pod`中增加了一个容器`istio-proxy`，同时也增加了一个`istio-init`的`initContainers`。

  