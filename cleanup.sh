#!/usr/bin/env bash

set -eo pipefail

echo "=========================================="
echo "  Observability Stack Cleanup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Step 1: Uninstall Helm release
echo "Step 1: Uninstalling Helm release..."
if helm list -n observability 2>/dev/null | grep -q observability; then
    helm uninstall observability -n observability 2>/dev/null && \
        print_status "Helm release 'observability' uninstalled" || \
        print_warning "Helm uninstall had issues (may already be deleted)"
else
    print_status "No Helm release found (already clean)"
fi
echo ""

# Step 2: Aggressively delete resources first (speeds up namespace deletion)
echo "Step 2: Deleting resources to speed up cleanup..."
NAMESPACES=("app" "observability")

for ns in "${NAMESPACES[@]}"; do
    if kubectl get ns "$ns" 2>/dev/null | grep -q "$ns"; then
        echo "  Cleaning up resources in '$ns' namespace..."
        # Delete deployments, statefulsets, daemonsets first (they take longest)
        kubectl delete deployments,statefulsets,daemonsets --all -n "$ns" --grace-period=0 --force 2>/dev/null || true
        # Delete PVCs that might block
        kubectl delete pvc --all -n "$ns" --grace-period=0 --force 2>/dev/null || true
        # Delete everything else (safe to run even if resources don't exist)
        kubectl delete all --all -n "$ns" --grace-period=0 --force 2>/dev/null || true
        # Delete CRDs and other resources that might block
        kubectl delete crds,servicemonitors,prometheusrules --all -n "$ns" --grace-period=0 --force 2>/dev/null || true
    else
        print_status "Namespace '$ns' does not exist, skipping resource cleanup"
    fi
done
echo ""

# Step 3: Delete namespaces
echo "Step 3: Deleting namespaces..."
DELETED_NAMESPACES=()

for ns in "${NAMESPACES[@]}"; do
    if kubectl get ns "$ns" 2>/dev/null | grep -q "$ns"; then
        # Check if namespace is already terminating
        NS_STATUS=$(kubectl get ns "$ns" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
        if [ "$NS_STATUS" = "Terminating" ]; then
            print_warning "Namespace '$ns' is already terminating, waiting for completion..."
            DELETED_NAMESPACES+=("$ns")
        else
            kubectl delete ns "$ns" 2>/dev/null && \
                print_status "Namespace '$ns' deletion initiated" || \
                print_warning "Failed to delete namespace '$ns' (may already be deleting)"
            DELETED_NAMESPACES+=("$ns")
        fi
    else
        print_status "Namespace '$ns' does not exist (already clean)"
    fi
done
echo ""

# Step 4: Wait for namespace deletion (with shorter timeout since we pre-deleted resources)
if [ ${#DELETED_NAMESPACES[@]} -gt 0 ]; then
    echo "Step 4: Waiting for namespaces to be fully deleted..."
    TIMEOUT=45
    ELAPSED=0
    
    for ns in "${DELETED_NAMESPACES[@]}"; do
        echo -n "  Waiting for '$ns' namespace to be deleted"
        while [ $ELAPSED -lt $TIMEOUT ]; do
            if ! kubectl get ns "$ns" 2>&1 | grep -q "$ns"; then
                echo ""
                print_status "Namespace '$ns' deleted successfully"
                break
            fi
            sleep 1
            ELAPSED=$((ELAPSED + 1))
            if [ $((ELAPSED % 5)) -eq 0 ]; then
                echo -n "."
            fi
        done
        
        if kubectl get ns "$ns" 2>&1 | grep -q "$ns"; then
            echo ""
            print_warning "Namespace '$ns' still deleting after ${TIMEOUT}s, forcing deletion..."
            # Try to remove finalizers if stuck
            kubectl patch ns "$ns" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
            kubectl delete ns "$ns" --force --grace-period=0 2>/dev/null || true
            sleep 2
            if ! kubectl get ns "$ns" 2>&1 | grep -q "$ns"; then
                print_status "Namespace '$ns' force deleted successfully"
            else
                print_warning "Namespace '$ns' may still be stuck. Manual cleanup may be needed."
            fi
        fi
        ELAPSED=0
    done
    echo ""
fi

# Step 5: Verify cleanup
echo "Step 5: Verifying cleanup..."
VERIFICATION_FAILED=false

for ns in "${NAMESPACES[@]}"; do
    if kubectl get ns "$ns" 2>&1 | grep -q "$ns" && ! kubectl get ns "$ns" 2>&1 | grep -q "NotFound"; then
        print_error "Namespace '$ns' still exists!"
        VERIFICATION_FAILED=true
    fi
done

# Check for any remaining resources
echo ""
echo "Checking for remaining resources..."
REMAINING_RESOURCES=$(kubectl get all -n app 2>/dev/null | wc -l || echo "0")
if [ "$REMAINING_RESOURCES" -gt "1" ]; then
    print_warning "Some resources may still exist in 'app' namespace"
    kubectl get all -n app 2>/dev/null || true
fi

REMAINING_OBS=$(kubectl get all -n observability 2>/dev/null | wc -l || echo "0")
if [ "$REMAINING_OBS" -gt "1" ]; then
    print_warning "Some resources may still exist in 'observability' namespace"
    kubectl get all -n observability 2>/dev/null || true
fi

# Final summary
echo ""
echo "=========================================="
if [ "$VERIFICATION_FAILED" = true ]; then
    print_error "Cleanup completed with warnings"
    echo ""
    echo "Some resources may still exist. To force cleanup:"
    echo "  kubectl delete ns app observability --force --grace-period=0"
    exit 1
else
    print_status "Cleanup completed successfully!"
    echo ""
    echo "All resources have been removed."
    echo "You can now run: ./deploy.sh"
    exit 0
fi

