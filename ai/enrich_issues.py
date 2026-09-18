import os
import json
import snowflake.connector
from openai import OpenAI
from dotenv import load_dotenv



load_dotenv()
MODEL = "gpt-4o-mini"

SAMPLE_N = int(os.getenv("SAMPLE_N", "10"))

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

SYSTEM_PROMPT = """
You are an AI system responsible for classifying the severity of GitHub issues.

Your task is to analyze a GitHub issue and classify its severity based only on the information provided in the issue title, body and available context.

Severity levels:

- "critical": The issue causes a severe impact such as complete system unavailability, data loss, security vulnerability with significant impact, or a failure affecting a fundamental system function with no practical workaround.
- "high": The issue significantly affects an important functionality, causes frequent failures, major performance degradation, or substantially impacts users, but does not completely prevent the system from operating.
- "medium": The issue affects functionality or usability but has a limited impact, affects a specific scenario, or has a reasonable workaround.
- "low": The issue has minor impact, cosmetic problems, small improvements, documentation issues, or problems that do not significantly affect functionality.

Important rules:

1. Base the classification only on the information contained in the input.
2. Do not assume technical details that are not explicitly stated or reasonably supported by the issue.
3. Do not use the issue's GitHub labels as the severity itself. Labels are contextual evidence only.
4. Do not infer severity from the author's tone or emotional language.
5. If the available information is insufficient, choose the severity that is best supported by the evidence and lower the confidence.
6. Return ONLY valid JSON. Do not include Markdown, explanations outside the JSON, or code fences.
7. The "confidence" value must be a number between 0 and 1.
8. The "evidence" field must contain short, concrete observations from the issue that support the classification.
9. The "reasoning" field must briefly explain why the evidence supports the selected severity.

Expected JSON structure:

{
  "severity": "critical | high | medium | low",
  "confidence": 0.0,
  "reasoning": "Short explanation of the classification.",
  "evidence": "Concrete evidence from the issue" 
}



"""

def get_connection():
    return snowflake.connector.connect(
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
        database=os.getenv("SNOWFLAKE_DATABASE"),
        schema=os.getenv("SNOWFLAKE_SCHEMA")

    )

def create_output_table(cursor):
    cursor.execute("CREATE SCHEMA IF NOT EXISTS GITPROJ.AI")
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS GITPROJ.AI.ISSUES_ENRICH(
        issue_id STRING,
        title STRING,
        body STRING,
        severity STRING,
        confidence FLOAT,
        reasoning STRING,
        evidence STRING,
        model_name STRING,
        enriched_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
        
    )

""")

def get_issues_to_enrich(cursor):
    cursor.execute(f"""
        SELECT
            f.issue_id,
            f.title,
            f.body
        FROM GITPROJ.GOLD.fact_issues f
        WHERE NOT EXISTS (
            SELECT 1
            FROM GITPROJ.AI.ISSUES_ENRICH e
            WHERE e.issue_id = f.issue_id
        )
        LIMIT {SAMPLE_N}
    """)
    return cursor.fetchall()


def classify_issue(title, body):
    response = client.chat.completions.create(
        model=MODEL,
        temperature=0,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {
                "role": "user",
                "content": f"""
    Title:
    {title}

    Body:
    {body}

    """
                }
            ]
        )
    answer = response.choices[0].message.content
    return json.loads(answer)


def save_results(cursor, results):
    cursor.executemany("""
        INSERT INTO GITPROJ.AI.ISSUES_ENRICH (
            issue_id,
            title,
            body,
            severity,
            confidence,
            reasoning,
            evidence,
            model_name
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """, results)

def main():
    conn = get_connection()
    cursor = conn.cursor()
    create_output_table(cursor)
    issues = get_issues_to_enrich(cursor)
    if len(issues) == 0:
        print("No Issues to enrich")
        cursor.close()
        conn.close()
        return

    print(f"Enirching {len(issues)} issues...")

    results = []
    for issue_id, title, body in issues:
        try:
            classification = classify_issue(title, body)
            results.append((
                issue_id,
                title,
                body,
                classification['severity'],
                classification['confidence'],
                classification['reasoning'], 
                classification['evidence'], 
                MODEL
            ))
        except Exception as e:
            print(f"Error occurred while classifying issue {issue_id}: {e}")

    if results:
        save_results(cursor, results)
        conn.commit()
        print(f"Successfully enriched {len(results)} issues.")
    else:
        print("No issues were enriched.")
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
