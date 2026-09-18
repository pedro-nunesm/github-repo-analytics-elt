import json
import os
import shutil
import subprocess
import sys
import time

import boto3
import requests


OWNER = os.getenv("GITHUB_OWNER", "pallets")
REPO = os.getenv("GITHUB_REPO", "flask")
S3_BUCKET = os.getenv("S3_BUCKET", "github-repo-analytics-elt")

LOCAL_DIR = "temp_github_data"
BASE_URL = f"https://api.github.com/repos/{OWNER}/{REPO}"


def get_github_token():
    token = os.getenv("GITHUB_TOKEN")

    if token:
        return token

    gh_path = shutil.which("gh")

    if not gh_path:
        raise RuntimeError(
            "GITHUB_TOKEN is not set and GitHub CLI was not found."
        )

    return subprocess.check_output(
        [gh_path, "auth", "token"],
        text=True,
    ).strip()


GITHUB_TOKEN = get_github_token()

HEADERS = {
    "Accept": "application/vnd.github+json",
    "Authorization": f"Bearer {GITHUB_TOKEN}",
}

s3 = boto3.client("s3")


def check_rate_limit(session):
    response = session.get(
        "https://api.github.com/rate_limit",
        timeout=30,
    )

    if response.status_code != 200:
        print("Could not check GitHub API rate limit.")
        return

    limit = response.json()["resources"]["core"]

    print("\nGitHub API rate limit")
    print(f"  Limit     : {limit['limit']}")
    print(f"  Used      : {limit['used']}")
    print(f"  Remaining : {limit['remaining']}")
    print()


def extract(
    session,
    endpoint,
    s3_folder,
    filename,
    params=None,
    max_pages=30,
):
    query = dict(params or {})
    query["per_page"] = 100

    os.makedirs(LOCAL_DIR, exist_ok=True)

    local_file = os.path.join(LOCAL_DIR, filename)

    print(f"\nExtracting /{endpoint}")

    with open(local_file, "w", encoding="utf-8") as file:
        for page in range(1, max_pages + 1):
            query["page"] = page

            response = session.get(
                f"{BASE_URL}/{endpoint}",
                params=query,
                timeout=30,
            )

            if response.status_code == 403:
                print("GitHub API request was forbidden or rate limit was reached.")
                return False

            if response.status_code != 200:
                print(
                    f"GitHub API error {response.status_code}: "
                    f"{response.text}"
                )
                return False

            records = response.json()

            if not records:
                break

            for record in records:
                file.write(
                    json.dumps(
                        record,
                        ensure_ascii=False,
                    )
                    + "\n"
                )

            print(f"  Page {page}: {len(records)} records")

            if len(records) < query["per_page"]:
                break

            time.sleep(0.5)

    s3_key = f"raw/{s3_folder}/{filename}"

    s3.upload_file(
        local_file,
        S3_BUCKET,
        s3_key,
    )

    print(f"Uploaded: s3://{S3_BUCKET}/{s3_key}")

    os.remove(local_file)

    print(f"Finished: {filename}")

    return True


def main():
    with requests.Session() as session:
        session.headers.update(HEADERS)

        check_rate_limit(session)

        extractions = [
            (
                "labels",
                "labels",
                "labels_raw.json",
                None,
                2,
            ),
            (
                "milestones",
                "milestones",
                "milestones_raw.json",
                {"state": "all"},
                30,
            ),
            (
                "issues",
                "issues",
                "issues_raw.json",
                {"state": "all"},
                100,
            ),
            (
                "issues/comments",
                "comments",
                "comments_raw.json",
                None,
                100,
            ),
        ]

        for endpoint, folder, filename, params, max_pages in extractions:
            success = extract(
                session,
                endpoint,
                folder,
                filename,
                params=params,
                max_pages=max_pages,
            )

            if not success:
                sys.exit(1)

        check_rate_limit(session)

    print("Extraction completed successfully.")


if __name__ == "__main__":
    main()
