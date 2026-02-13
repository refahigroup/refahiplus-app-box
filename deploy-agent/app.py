import os
import subprocess
from typing import Optional, Literal

from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel

app = FastAPI(title="Refahi Deploy Agent", version="1.0.0")

DEPLOY_TOKEN = os.getenv("DEPLOY_TOKEN", "").strip()
DEPLOY_SCRIPT = "/opt/refahi-infra/deploy-agent/deploy.sh"


class DeployRequest(BaseModel):
    env: Literal["prod", "stage"]
    service: str  # e.g. webapi, webapp, identity, notif, all


def check_auth(authorization: Optional[str]):
    if not DEPLOY_TOKEN:
        raise HTTPException(status_code=500, detail="DEPLOY_TOKEN is not configured")

    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")

    token = authorization.replace("Bearer ", "").strip()
    if token != DEPLOY_TOKEN:
        raise HTTPException(status_code=403, detail="Invalid token")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/deploy")
def deploy(req: DeployRequest, authorization: Optional[str] = Header(default=None)):
    check_auth(authorization)

    allowed_services = {"api", "webapp", "identity", "notif", "all", "refahigroup-website"}
    if req.service not in allowed_services:
        raise HTTPException(status_code=400, detail=f"Invalid service '{req.service}'")

    cmd = [DEPLOY_SCRIPT, req.env, req.service]

    try:
        result = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
            timeout=600,
        )
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=500, detail="Deploy script timed out")
    except subprocess.CalledProcessError as ex:
        raise HTTPException(
            status_code=500,
            detail={
                "message": "Deploy script failed",
                "stdout": ex.stdout,
                "stderr": ex.stderr,
                "returncode": ex.returncode,
            },
        )

    return {
        "status": "ok",
        "env": req.env,
        "service": req.service,
        "stdout": result.stdout,
        "stderr": result.stderr,
    }
