import sqlite3
from pathlib import Path

conn = sqlite3.connect(Path("car_washing.db"))
conn.row_factory = sqlite3.Row
cur = conn.cursor()

print("--- accounts ---")
for r in cur.execute(
    "SELECT id, username, email, role, display_name, approval_status, "
    "free_wash_credits, prepaid_wash_credits, share_code, referred_by_user_id "
    "FROM accounts ORDER BY created_at"
):
    print(dict(r))

print("\n--- stores ---")
for r in cur.execute(
    "SELECT id, owner_account_id, name, address, approval_status, service_types "
    "FROM stores ORDER BY created_at"
):
    print(dict(r))

print("\n--- payment_records ---")
for r in cur.execute(
    "SELECT id, order_id, method, amount, status, demo_mode, created_at "
    "FROM payment_records ORDER BY created_at"
):
    print(dict(r))

print("\n--- email_verifications (summary) ---")
for r in cur.execute(
    "SELECT purpose, COUNT(*) as cnt, SUM(CASE WHEN used THEN 1 ELSE 0 END) as used_cnt "
    "FROM email_verifications GROUP BY purpose"
):
    print(dict(r))

conn.close()
