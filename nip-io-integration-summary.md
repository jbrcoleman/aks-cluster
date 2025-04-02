# nip.io Integration for AKS, Istio, and ArgoCD

## Overview

We've updated the infrastructure to automatically use nip.io domains based on the Istio ingress gateway's external IP. This eliminates the need for manual DNS configuration and provides a zero-setup approach to accessing your services.

## How nip.io Works

The nip.io service provides wildcard DNS for any IP address. For example, if your Istio ingress gateway IP is `51.138.42.90`, you can access your services at:
- argocd.51.138.42.90.nip.io
- historical-network.51.138.42.90.nip.io
- kiali.51.138.42.90.nip.io

The nip.io DNS server automatically resolves these domains to `51.138.42.90`, making it perfect for testing and development environments.

## Implementation Details

1. **Terraform Variables**: Added a `use_nip_io` variable (defaults to true) to control whether to use nip.io domains.

2. **Dynamic IP Detection**: Added a data source to fetch the Istio ingress gateway's external IP.

3. **Domain Configuration**: Created local variables to generate the appropriate domains based on the ingress IP.

4. **ArgoCD Configuration**: Updated the ArgoCD gateway and virtual service to use the nip.io domain.

5. **Istio Templates**: Modified the Istio gateway and virtual service templates to use Helm variables for the domains.

6. **Application Configuration**: Added domain configuration for the Historical Network application.

7. **Helper Script**: Created a script to verify and display the nip.io domains once Istio is deployed.

## Benefits

- **Zero Configuration**: No need to register a domain or configure DNS records
- **Automatic Setup**: Domains are generated based on the assigned external IP
- **Immediate Access**: Services are accessible as soon as they're deployed
- **Flexibility**: Can still use a custom domain by setting `use_nip_io = false`
- **Predictable Naming**: Consistent domain pattern for all services

## Usage

After running the setup script, you'll receive a list of nip.io domains for all your services. You can immediately access these domains in your browser without any additional configuration.

For local testing, you can also add entries to your `/etc/hosts` file:
```
51.138.42.90 argocd.51.138.42.90.nip.io historical-network.51.138.42.90.nip.io kiali.51.138.42.90.nip.io grafana.51.138.42.90.nip.io
```

## Limitations

- Not ideal for production environments where you want professional, branded domains
- Some corporate networks might block wildcard DNS services for security reasons
- IP addresses can change if you recreate the ingress gateway
- Not suitable for HTTPS/TLS without additional configuration
- DNS resolution depends on the nip.io service being available

## Moving to Production

When you're ready to move to a production environment, you can:

1. Purchase a custom domain
2. Set `use_nip_io = false` and provide your domain in `domain_name`
3. Configure your DNS provider to point your domain to the Istio ingress gateway IP
4. Set up TLS certificates for secure HTTPS access

## Troubleshooting

### Domain resolution issues

If you can't access the services using the nip.io domains:

1. Verify the Istio ingress gateway has an external IP:
   ```bash
   kubectl get svc -n istio-system istio-ingressgateway
   ```

2. Test DNS resolution:
   ```bash
   ping your-ip.nip.io
   ```

3. Check if your network allows access to wildcard DNS services.

### ArgoCD not displaying services

If ArgoCD is accessible but doesn't show your applications:

1. Check the application sync status:
   ```bash
   kubectl get applications -n argocd
   ```

2. View detailed sync information:
   ```bash
   kubectl describe application istio -n argocd
   ```

3. Check for any errors in the ArgoCD logs:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
   ```

### Istio services not working

If you can access ArgoCD but other Istio-managed services are unavailable:

1. Verify the Gateway and VirtualService resources:
   ```bash
   kubectl get gateway,virtualservice -A
   ```

2. Check that the services are correctly deployed:
   ```bash
   kubectl get pods -n istio-system
   ```

3. Check the Istio ingress gateway logs:
   ```bash
   kubectl logs -n istio-system -l app=istio-ingressgateway
   ```

## Conclusion

The nip.io integration provides a seamless way to access your AKS services without manual DNS configuration. It's perfect for development, testing, and demonstration environments, allowing you to focus on your application rather than infrastructure setup.

When you're ready to move to production, you can easily switch to a custom domain while keeping the same infrastructure configuration.