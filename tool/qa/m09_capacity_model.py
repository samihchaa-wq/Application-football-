#!/usr/bin/env python3
"""Modèle budgétaire M09, hors réseau : hypothèses, jamais un benchmark.

Reproduction : python3 tool/qa/m09_capacity_model.py
Sensibilité : python3 tool/qa/m09_capacity_model.py --teams-per-club 10
Tous les prix sont des USD indicatifs, hors taxes, datés du 16/11/2026.
Les postes non mesurés sont signalés ; aucun achat/configuration n'est réalisé.
"""
from __future__ import annotations

import argparse
import json
import math


def positive(value: str) -> int:
    result = int(value)
    if result < 1:
        raise argparse.ArgumentTypeError("Un entier strictement positif est requis.")
    return result


def scenario(clubs: int, teams_per_club: int) -> dict:
    teams = clubs * teams_per_club
    memberships = teams * 30
    active = math.ceil(memberships * 0.20)
    mau = math.ceil(memberships * 0.70)
    simultaneous_team_matches = math.ceil(teams * 0.25)
    messages = mau * 240 * 4
    egress_gb = memberships * 20 / 1000
    media_gb = (memberships * 0.75 + teams * 2) / 1000
    database_gb = 0.05 + memberships * 0.0001 + teams * 40 * 0.00005
    compute = 15 if clubs <= 30 else 60 if clubs <= 300 else 111
    realtime_connections = math.ceil(max(0, active - 500) / 1000) * 10
    # Arrondi de prudence budgétaire, pas une règle de facturation affirmée.
    realtime_messages = math.ceil(max(0, messages - 5_000_000) / 1_000_000) * 2.5
    supplier_components = {
        "pro_plan_plus_compute_minus_single_org_credit": 25 + compute - 10,
        "realtime_peak_connections": realtime_connections,
        "realtime_messages_rounded_budget_allowance": realtime_messages,
        "uncached_egress_assumption": round(max(0, egress_gb - 250) * 0.09, 2),
        "storage_above_100gb": round(max(0, media_gb - 100) * 0.021, 2),
        "database_disk_above_8gb": round(max(0, database_gb - 8) * 0.125, 2),
        "auth_above_100k_mau": round(max(0, mau - 100_000) * 0.00325, 2),
    }
    # Réserves de planification : aucun fournisseur ni prix souscrit.
    other_allowances = {
        "functional_staging_micro_compute_no_second_org_credit": 10,
        "private_independent_backups_not_a_quote": 10 if clubs <= 30 else 15 if clubs <= 300 else 25,
        "transactional_email_not_a_quote": 10 if clubs <= 30 else 20 if clubs <= 300 else 30,
        "logs_monitoring_not_a_quote": 5 if clubs <= 30 else 15 if clubs <= 300 else 40,
    }
    subtotal = round(sum(supplier_components.values()), 2)
    planning_total = round(subtotal + sum(other_allowances.values()), 2)
    return {
        "status": "estimate_not_measured_not_authorized_spend",
        "clubs_registered_and_active_assumed": clubs,
        "teams": teams,
        "memberships_upper_bound_unique_accounts": memberships,
        "mau_assumed": mau,
        "simultaneous_devices_and_sockets_assumed": active,
        "realtime_channels_assumed_four_per_device": active * 4,
        "simultaneous_team_matches": simultaneous_team_matches,
        "api_steady_rps_at_six_per_minute": round(active * 6 / 60, 2),
        "login_rps_ten_percent_in_five_minutes": round(memberships * 0.10 / 300, 2),
        "opening_api_extra_rps_at_eight_per_login": round(memberships * 0.10 / 300 * 8, 2),
        "prediction_write_rps_twenty_percent_in_five_minutes": round(memberships * 0.20 / 300, 2),
        "live_write_rps_two_per_match_per_minute": round(simultaneous_team_matches * 2 / 60, 2),
        "realtime_delivered_messages_per_second_at_peak": round(active * 4 / 60, 2),
        "realtime_delivered_messages_per_month": messages,
        "egress_gb_per_month_all_uncached_assumed": round(egress_gb, 3),
        "media_gb_assumed": round(media_gb, 3),
        "database_gb_one_season_assumed": round(database_gb, 3),
        "private_backup_gb_fourteen_full_copies_uncompressed_assumed": round(14 * (media_gb + database_gb), 3),
        "candidate_compute_monthly_usd_not_validated": compute,
        "supplier_budget_components_usd": supplier_components,
        "supplier_subtotal_usd": subtotal,
        "other_monthly_allowances_usd": other_allowances,
        "monthly_total_before_contingency_usd": planning_total,
        "monthly_total_with_25_percent_contingency_usd": round(planning_total * 1.25, 2),
        "exceeds_documented_pro_default_500_realtime_connections": active > 500,
        "exceeds_documented_pro_no_spend_cap_default_10000_connections": active > 10_000,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--teams-per-club", type=positive, default=3)
    parser.add_argument("--clubs", type=positive, nargs="+", default=[3, 30, 100, 300, 500])
    args = parser.parse_args()
    result = {
        "as_of": "2026-11-16",
        "classification": "planning_estimates_only_no_measured_capacity",
        "currency": "USD_excluding_taxes_exchange_fees_and_unpriced_services",
        "assumptions": {
            "teams_per_club": args.teams_per_club,
            "memberships_per_team": 30,
            "peak_fraction_of_memberships": 0.20,
            "monthly_active_fraction": 0.70,
            "devices_per_peak_member": 1,
            "realtime_sockets_per_device": 1,
            "realtime_channels_per_device": 4,
            "six_api_calls_per_active_device_per_minute": True,
            "monthly_active_minutes_per_mau": 240,
            "realtime_delivered_messages_per_device_per_minute": 4,
            "media_mb_per_member": 0.75,
            "other_media_mb_per_team": 2,
            "supabase_egress_mb_per_membership_per_month": 20,
            "annual_matches_per_team": 40,
            "database_kb_per_membership": 100,
            "database_kb_per_match": 50,
            "database_fixed_mb": 50,
            "backup_full_copies": 14,
            "one_organization_one_pro_subscription_one_compute_credit": True,
            "all_quotas_assumed_available_for_petit_filet_only": True,
        },
        "excluded_from_cost": [
            "actual_shared_org_usage_and_invoices_unknown",
            "extra_edge_invocations_beyond_included_quota_unknown",
            "paid_cloudflare_services_domain_payment_fees_taxes",
            "video_user_uploads_and_image_transformation_usage",
            "paid_legal_security_review_support_labor",
            "representative_hosted_load_test_environment_runtime",
            "PITR_not_enabled_or_budgeted",
        ],
        "sources": [
            "https://supabase.com/docs/guides/platform/manage-your-usage/compute",
            "https://supabase.com/docs/guides/platform/billing-on-supabase",
            "https://supabase.com/docs/guides/platform/manage-your-usage/realtime-peak-connections",
            "https://supabase.com/docs/guides/platform/manage-your-usage/realtime-messages",
            "https://supabase.com/docs/guides/platform/manage-your-usage/egress",
            "https://supabase.com/docs/guides/realtime/limits",
        ],
        "scenarios": [scenario(clubs, args.teams_per_club) for clubs in args.clubs],
    }
    print(json.dumps(result, ensure_ascii=False, indent=2) + "\n", end="")


if __name__ == "__main__":
    main()
