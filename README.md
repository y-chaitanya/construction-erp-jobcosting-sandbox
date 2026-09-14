# 🏗️ Construction ERP Job-Costing Data Sandbox

A relational database sandbox modelling the backend data architecture of
construction and field-service ERP systems — the structure sitting underneath
platforms like Viewpoint Vista and Sage 300 CRE.

Not a schema diagram and not a tutorial copy — a working SQLite database with
real job cost variance calculations and an automated exception-audit view that
I had to fix after it flagged my own valid data.

> ⚠️ **Sandbox note.** All records are fictional and synthetically generated. I
> have not worked inside Vista or Sage. I built this to understand how these
> systems structure their data, working from publicly available documentation of
> how construction ERPs organise job costing.

---

## 🎯 Why I built this

Construction job costing is where the office and the field meet, and it's where
the data usually breaks.

A crew logs hours on a phone in a truck. A supplier sends an invoice weeks later.
Somebody in the office estimated the job months before either of those happened.
All three have to land in the same ledger, tagged to the same cost code, before
anyone can answer the only question that matters: **are we over or under on this
job, and by how much?**

I wanted to understand that structure from the data side rather than read about
it. So I built the tables, loaded them with realistic entries, and wrote the
queries that produce the variance.

---

## 🗄️ What's in it

Four objects, each modelling a different part of a real system.

| Object | What it represents |
|---|---|
| `erp_job_estimates` | Corporate budgeting — project cost codes and baseline allocations, set before work starts |
| `field_labor_logs` | Live field data — crew timecard entries as they'd arrive from a mobile app |
| `vendor_material_invoices` | Accounts payable — supplier invoices linked back to the job |
| `erp_data_exceptions_audit` | A validation view that isolates human input anomalies before they reach cost reporting |

The three data tables link through primary and composite keys, so labour and
materials both roll up to the same cost code as the original estimate.

**Job cost variance** is calculated by aggregating actual labour and material
cost against the baseline allocation — `LEFT JOIN`, `SUM`, `GROUP BY`. LEFT JOIN
rather than INNER, deliberately: a cost code with a budget and no spend yet is
information, not an absence. An inner join would silently drop it.

---

## 🔍 The bug I'm most glad I found

**My first version of the audit view flagged my own valid data.**

The rule was simple and obvious: flag any labour entry over 16 hours. Nobody
works a 17-hour shift, so anything above that is a typo or a fraud.

Then I ran it against my baseline records — 40 hours, 40 hours, 35 hours — and
every single one came back as an exception.

The rule wasn't wrong. My assumption about the data was. Those entries weren't
daily shifts, they were **accumulated weekly logs**. A 40-hour week is not a
40-hour day, and my rule couldn't tell the difference because I hadn't thought
about what the number actually represented.

**The fix** was a conditional `CASE` statement with `OR` logic, so the view
evaluates entries against the right expectation:

- Standard weekly accumulations pass cleanly
- A **negative entry** — `-5` hours — is trapped
- A **single-shift overrun typo** — 24 hours in one day — is trapped

Both real anomalies still get caught. Valid data no longer does.

### Why this is the part worth writing down

A control that flags correct data gets switched off. And once it's switched off,
it isn't protecting anything.

That's the actual failure mode. Not "the rule was too strict" — the rule was too
strict *in a way that would cause someone to stop trusting it*, at which point
the real typo sails straight through.

I'd hit the same thing from the other direction in my
[AR aging analyzer](https://github.com/y-chaitanya/ar-aging-risk-analyzer),
where a fixed-range formula understated reported exposure by $30,750 once the
dataset grew and nothing on screen looked wrong. One error was a control that
fired when it shouldn't; the other was a calculation that stayed silent when it
should have shouted.

Same lesson from both: **the dangerous errors are the quiet ones, and a
validation rule is only useful if people leave it switched on.**

---

## 🛠️ SQL practised here

- Multi-module relational schema design with composite keys
- Aggregation across joined tables — `LEFT JOIN`, `SUM`, `GROUP BY`
- Cost centre variance calculation against baseline allocations
- Conditional logic in views — `CASE`, `OR` — for exception auditing
- Data governance framing: catching anomalies at the data layer rather than
  relying on the entry screen

**Stack:** SQLite · SQL

---

## 📓 Notes on scope, so nothing here is oversold

- **The data is synthetic.** I generated the records myself.
- **I have not worked inside Vista, Sage 300 CRE or any production ERP.** This
  models the structure those systems use, based on public documentation of how
  construction job costing is organised. A real implementation would differ in
  ways I don't know about yet.
- **The schema is simplified.** A production system carries labour burden rates,
  equipment costs, change orders, retainage, subcontractor commitments and
  revenue recognition. I modelled the core loop: estimate → actual → variance.
- **The thresholds are my own judgment**, written down so they can be argued
  with. 16 hours as a daily ceiling is a reasonable guess, not an industry
  standard.

---

## 📌 About

Part of a deliberate, hands-on return to technical work — documented end to end,
including the parts that didn't work first time.

Other projects:
[Water Utility Operations Database](https://github.com/y-chaitanya/water-utility-operations-database) ·
[AR Aging & Write-Off Risk Analyzer](https://github.com/y-chaitanya/ar-aging-risk-analyzer) ·
[Enterprise CRM & Workflow Automation Sandbox](https://github.com/y-chaitanya/enterprise-crm-workflow-automation-sandbox) ·
[Autoclave Cure Cycle Deviation Analyzer](https://github.com/y-chaitanya/autoclave-cure-analyzer)
