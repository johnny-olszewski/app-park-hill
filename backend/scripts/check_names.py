"""Checks contract/names.json against the running local Supabase: every RPC
function exists in `public` and is executable by a client role, every Edge
Function has a folder, and the screen keys match the `screens` table exactly.
Run by `make data-check` after a reset."""

import sys

import names
from dataset import REPO
from local_supabase import LocalSupabase

FUNCTIONS_PATH = REPO / "backend" / "supabase" / "functions"

FUNCTIONS_QUERY = """
select p.proname,
       bool_or(has_function_privilege('anon', p.oid, 'EXECUTE')
            or has_function_privilege('authenticated', p.oid, 'EXECUTE'))
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
group by p.proname
"""


def main() -> int:
    try:
        data = names.load()
    except names.NamesError as error:
        print(f"names.json: {error}")
        return 1

    supabase = LocalSupabase()
    problems: list[str] = []

    executable = {name: flag == "t" for name, flag in supabase.sql(FUNCTIONS_QUERY)}
    for function in data["rpc_functions"]:
        if function not in executable:
            problems.append(f"rpc function {function}: not in the database's public schema")
        elif not executable[function]:
            problems.append(f"rpc function {function}: not executable by anon or authenticated")

    for function in data["edge_functions"]:
        if not (FUNCTIONS_PATH / function).is_dir():
            problems.append(f"edge function {function}: no folder in backend/supabase/functions")

    screens = {row[0] for row in supabase.sql("select key from public.screens")}
    listed = set(data["screen_keys"])
    for key in sorted(listed - screens):
        problems.append(f"screen key {key}: in names.json but not in the screens table")
    for key in sorted(screens - listed):
        problems.append(f"screen key {key}: in the screens table but not in names.json")

    for problem in problems:
        print(problem)
    if problems:
        return 1
    print("Names match the backend: " + ", ".join(sum((data[g] for g in names.GROUPS), [])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
