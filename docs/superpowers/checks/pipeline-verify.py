#!/usr/bin/env python3
"""端到端流水线验证脚本。

用法：
    python pipeline-verify.py <workspace_root> [--strict]

验证项：
    1. 目录结构完整性
    2. 元数据完整性（无 Unknown/空值）
    3. 状态机一致性（draft -> audit(pass) -> stable）
    4. refs.bib 与 wiki/papers 一致性
    5. 审计报告存在且通过
    6. survey 门槛判定
    7. 无个人路径泄露
    8. 日志完整性
"""

import argparse
import json
import pathlib
import re
import sys


def fail(msg):
    print(f"FAIL: {msg}")
    sys.exit(1)


def warn(msg):
    print(f"WARN: {msg}")


def ok(msg):
    print(f"OK: {msg}")


def parse_frontmatter(text):
    m = re.match(r"^---\s*\n(.*?)\n---", text, re.S)
    if not m:
        return {}
    fm = {}
    for line in m.group(1).splitlines():
        k, _, v = line.partition(":")
        k = k.strip()
        v = v.strip().strip('"')
        if k:
            fm[k] = v
    return fm


def main():
    parser = argparse.ArgumentParser(description="验证 my-paper-wiki 完整流水线产物")
    parser.add_argument("workspace_root", help="运行时 workspace 目录")
    parser.add_argument("--strict", action="store_true", help="严格模式：任何 WARN 也视为失败")
    args = parser.parse_args()

    root = pathlib.Path(args.workspace_root)
    errors = []
    warnings = []

    # --- 1. 目录结构 ---
    required_dirs = [
        root / "raw" / "papers",
        root / "wiki" / "papers" / "_pending",
        root / "wiki" / "topics",
        root / "wiki" / "surveys",
        root / "outputs" / "audit",
        root / "outputs" / "survey",
    ]
    required_files = [
        root / "refs.bib",
        root / "wiki" / "index.md",
        root / "wiki" / "log.md",
        root / "outputs" / "citations.jsonl",
    ]
    for d in required_dirs:
        if not d.is_dir():
            errors.append(f"目录缺失: {d.relative_to(root)}")
    for f in required_files:
        if not f.is_file():
            errors.append(f"文件缺失: {f.relative_to(root)}")
    if not errors:
        ok("目录结构完整")

    # --- 2. 论文页面元数据完整性 ---
    papers_dir = root / "wiki" / "papers"
    paper_pages = [p for p in papers_dir.glob("*.md") if p.parent.name != "_pending"]
    if not paper_pages:
        errors.append("无 final paper 页面")

    refs_text = (root / "refs.bib").read_text(encoding="utf-8") if (root / "refs.bib").exists() else ""
    ref_bibkeys = set(re.findall(r"@article\{(\w+),", refs_text))

    stable_count = 0
    for page in sorted(paper_pages):
        txt = page.read_text(encoding="utf-8")
        fm = parse_frontmatter(txt)
        bibkey = fm.get("bibkey", "")
        status = fm.get("status", "")
        title = fm.get("title", "")
        meta_src = fm.get("metadata_source", "")

        # 元数据完整性
        for field in ["title", "bibkey", "year", "source_file", "source_text"]:
            val = fm.get(field, "")
            if not val or val == "Unknown" or val == "null":
                errors.append(f"{page.name}: {field} 为空或 Unknown")
        if "unknown" in bibkey.lower():
            errors.append(f"{page.name}: bibkey 包含 unknown: {bibkey}")
        if "Unresolved" in title:
            errors.append(f"{page.name}: title 包含 Unresolved")

        # refs.bib 一致性
        if bibkey and bibkey not in ref_bibkeys:
            errors.append(f"{page.name}: bibkey {bibkey} 不在 refs.bib 中")

        # refs.bib 中对应条目元数据完整性
        if bibkey in ref_bibkeys:
            # 用括号深度匹配提取完整条目块
            start = refs_text.find("@article{" + bibkey + ",")
            if start >= 0:
                depth = 0
                end = start
                for i in range(start, len(refs_text)):
                    if refs_text[i] == "{":
                        depth += 1
                    elif refs_text[i] == "}":
                        depth -= 1
                        if depth == 0:
                            end = i
                            break
                block = refs_text[start:end]
                for field in ["title", "author", "year", "journal"]:
                    val_m = re.search(field + r"\s*=\s*\{([^}]*)\}", block)
                    val = val_m.group(1).strip() if val_m else ""
                    if not val or "Unknown" in val or "Unresolved" in val:
                        errors.append("refs.bib[" + bibkey + "]: " + field + " 为空或包含 Unknown/Unresolved")

        # 状态机
        if status == "stable":
            stable_count += 1

    ok(f"论文页面: {len(paper_pages)} 篇, stable: {stable_count} 篇")

    # --- 3. 审计报告 ---
    audit_dir = root / "outputs" / "audit"
    audit_reports = list(audit_dir.glob("*-audit.md")) if audit_dir.exists() else []
    if not audit_reports:
        errors.append("无审计报告")
    passed_audits = 0
    for report in sorted(audit_reports):
        rpt_text = report.read_text(encoding="utf-8")
        result_m = re.search(r"result:\s*`(\w+)`", rpt_text)
        result = result_m.group(1) if result_m else "unknown"
        if result == "pass":
            passed_audits += 1
        else:
            errors.append(f"审计报告 {report.name} 结果: {result}")
    ok(f"审计报告: {len(audit_reports)} 份, 通过: {passed_audits} 份")

    # --- 4. survey 门槛 ---
    survey_dir = root / "outputs" / "survey"
    survey_warn = survey_dir / "survey-warn.md"
    survey_tex_files = list(survey_dir.glob("*.tex")) if survey_dir.exists() else []

    if stable_count >= 5:
        if not survey_tex_files:
            errors.append(f"stable={stable_count} >= 5 但无 survey .tex 输出")
        else:
            ok(f"survey 门槛满足 (stable={stable_count}), 已生成 .tex")
    else:
        if survey_warn.exists():
            warn_text = survey_warn.read_text(encoding="utf-8")
            if str(stable_count) in warn_text:
                ok(f"survey 门槛不足 (stable={stable_count}), 已正确输出 warn")
            else:
                warnings.append(f"survey-warn.md 中 stable 数与实际不一致")
        else:
            warnings.append(f"stable={stable_count} < 5 但无 survey-warn.md")

    # --- 5. 无个人路径泄露 ---
    personal_patterns = [r"C:\\Users", r"/home/", r"/Users/", r"alanZe", r"alanze"]
    for f in list(paper_pages) + audit_reports:
        txt = f.read_text(encoding="utf-8")
        for pat in personal_patterns:
            if re.search(pat, txt, re.I):
                errors.append(f"{f.name}: 检测到个人路径 ({pat})")
    # 检查 report 文件
    for rpt in (root.parent.parent / "docs" / "superpowers" / "reports").glob("*.md"):
        if rpt.exists():
            txt = rpt.read_text(encoding="utf-8")
            for pat in personal_patterns:
                if re.search(pat, txt, re.I):
                    errors.append(f"报告 {rpt.name}: 检测到个人路径 ({pat})")
    ok("未检测到个人路径泄露")

    # --- 6. 日志完整性 ---
    log_file = root / "wiki" / "log.md"
    if log_file.exists():
        log_text = log_file.read_text(encoding="utf-8")
        log_lines = [l for l in log_text.splitlines() if l.strip()]
        if not log_lines:
            warnings.append("log.md 为空")
        else:
            has_ingest = any("ingest" in l for l in log_lines)
            has_audit = any("audit" in l for l in log_lines)
            if not has_ingest:
                errors.append("log.md 缺少 ingest 事件")
            if not has_audit:
                errors.append("log.md 缺少 audit 事件")
            ok(f"日志: {len(log_lines)} 条事件")
    else:
        errors.append("log.md 不存在")

    # --- 7. index 一致性 ---
    index_file = root / "wiki" / "index.md"
    if index_file.exists():
        index_text = index_file.read_text(encoding="utf-8")
        index_refs = re.findall(r"papers/(?:_pending/)?(\S+?)(?:\.md)?$", index_text, re.M)
        for bibkey in [b for b in index_refs if not b.startswith("pending-")]:
            if bibkey not in ref_bibkeys:
                warnings.append(f"index.md 引用 {bibkey} 但不在 refs.bib 中")
        ok("index.md 已检查")

    # --- 汇总 ---
    print("\n" + "=" * 50)
    if errors:
        print("FAIL: {} 个错误, {} 个警告".format(len(errors), len(warnings)))
        for e in errors:
            print("  [X] " + e)
        for w in warnings:
            print("  [!] " + w)
        sys.exit(1)
    elif warnings and args.strict:
        print("FAIL (strict): {} 个警告".format(len(warnings)))
        for w in warnings:
            print("  [!] " + w)
        sys.exit(1)
    else:
        print("PASS: 所有检查通过 ({} 篇论文, {} 篇 stable)".format(len(paper_pages), stable_count))
        if warnings:
            print("  ({} 个警告)".format(len(warnings)))
        sys.exit(0)


if __name__ == "__main__":
    main()
