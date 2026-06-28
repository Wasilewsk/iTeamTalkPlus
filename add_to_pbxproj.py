#!/usr/bin/env python3
"""
Add new Swift files to an Xcode project.pbxproj.

Inserts PBXBuildFile, PBXFileReference, group children, and
PBXSourcesBuildPhase entries for new Models, Views, and Tests.

Usage: python add_to_pbxproj.py
"""

import os

PBXPROJ = os.path.expanduser(
    r'C:\Users\natan\projects\Teamtalkpluss IOS\ios-project\iTeamTalkPlus\iTeamTalk.xcodeproj\project.pbxproj'
)

# ── New files to register ──────────────────────────────────────────────────

MODELS = [
    'GlobalChatViewModel.swift',
    'PrivateMessagesViewModel.swift',
    'MediaStreamingViewModel.swift',
    'FileManagementViewModel.swift',
    'ServerManagementViewModel.swift',
    'EventHistoryViewModel.swift',
    'ConnectionStatusViewModel.swift',
    'OnlineUsersViewModel.swift',
    'ManageStatusViewModel.swift',
    'TeamTalkService.swift',
]

VIEWS = [
    'GlobalChatView.swift',
    'PrivateMessagesView.swift',
    'MediaStreamingView.swift',
    'FileManagementView.swift',
    'ServerManagementView.swift',
    'EventHistoryView.swift',
    'ConnectionStatusView.swift',
    'OnlineUsersView.swift',
    'ManageStatusView.swift',
]

TESTS = [
    'TeamTalkPlusTests.swift',
]

# ── UUID generation ────────────────────────────────────────────────────────
# Existing UUID ranges:
#   Models:  CC000200...0001..000B  (file refs),  CC000300...0001..000B  (build)
#   Views:   CC000400...0001..0010  (file refs),  CC000500...0001..0010  (build)
#   Tests:   (none yet in CC namespace)
#
# New UUIDs continue from the last value in each range.

def make_uuids(base: str, first_suffix: int, count: int) -> list[str]:
    """Generate count 24-char hex UUIDs from base + 12-char incrementing suffix."""
    return [f'{base}{s:012X}' for s in range(first_suffix, first_suffix + count)]

# Models: last suffix was 000B (11), start at 000C (12)
MODEL_FREF = make_uuids('CC0002000000', 0x00C, len(MODELS))
MODEL_BF   = make_uuids('CC0003000000', 0x00C, len(MODELS))

# Views: last suffix was 0010 (16), start at 0011 (17)
VIEW_FREF  = make_uuids('CC0004000000', 0x011, len(VIEWS))
VIEW_BF    = make_uuids('CC0005000000', 0x011, len(VIEWS))

# Tests: fresh namespace
TEST_FREF  = ['CC0006000000000000000001']
TEST_BF    = ['CC0007000000000000000001']

# ── Helpers ────────────────────────────────────────────────────────────────

T = '\t'

def tab(n: int) -> str:
    return T * n

def fmt_build_line(uid: str, fref: str, filename: str) -> str:
    """PBXBuildFile entry (3 tabs)."""
    return f'{tab(3)}{uid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {fref} /* {filename} */; }};'

def fmt_ref_line(uid: str, filename: str) -> str:
    """PBXFileReference entry (3 tabs)."""
    return f'{tab(3)}{uid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};'

def fmt_child_line(uid: str, filename: str) -> str:
    """Group child entry (4 tabs)."""
    return f'{tab(4)}{uid} /* {filename} */,'

def fmt_source_line(uid: str, filename: str) -> str:
    """PBXSourcesBuildPhase entry (4 tabs)."""
    return f'{tab(4)}{uid} /* {filename} in Sources */,'

# ── Build insertion blocks ─────────────────────────────────────────────────

# PBXBuildFile block
build_lines = []
for i, fn in enumerate(MODELS):
    build_lines.append(fmt_build_line(MODEL_BF[i], MODEL_FREF[i], fn))
for i, fn in enumerate(VIEWS):
    build_lines.append(fmt_build_line(VIEW_BF[i], VIEW_FREF[i], fn))
for i, fn in enumerate(TESTS):
    build_lines.append(fmt_build_line(TEST_BF[i], TEST_FREF[i], fn))
BLD = '\n'.join(build_lines)

# PBXFileReference block
ref_lines = []
for i, fn in enumerate(MODELS):
    ref_lines.append(fmt_ref_line(MODEL_FREF[i], fn))
for i, fn in enumerate(VIEWS):
    ref_lines.append(fmt_ref_line(VIEW_FREF[i], fn))
for i, fn in enumerate(TESTS):
    ref_lines.append(fmt_ref_line(TEST_FREF[i], fn))
REF = '\n'.join(ref_lines)

# Group children blocks
GRP_MODEL = '\n'.join(fmt_child_line(MODEL_FREF[i], fn) for i, fn in enumerate(MODELS))
GRP_VIEW  = '\n'.join(fmt_child_line(VIEW_FREF[i], fn) for i, fn in enumerate(VIEWS))
GRP_TEST  = '\n'.join(fmt_child_line(TEST_FREF[i], fn) for i, fn in enumerate(TESTS))

# PBXSourcesBuildPhase blocks
SRC_IT    = '\n'.join(
    [fmt_source_line(MODEL_BF[i], fn) for i, fn in enumerate(MODELS)] +
    [fmt_source_line(VIEW_BF[i], fn) for i, fn in enumerate(VIEWS)]
)
SRC_TEST  = '\n'.join(fmt_source_line(TEST_BF[i], fn) for i, fn in enumerate(TESTS))

# ── Read file ──────────────────────────────────────────────────────────────

with open(PBXPROJ, 'r', encoding='utf-8') as f:
    content = f.read()

eol = '\r\n' if '\r\n' in content else '\n'

# ── Perform insertions ─────────────────────────────────────────────────────
# Each replacement targets a unique anchor string that we know exists.
# We use replace(..., 1) to replace only the first occurrence.

modified = False

# 1) PBXBuildFile – insert entries before closing marker
anchor = '/* End PBXBuildFile section */'
if anchor in content:
    content = content.replace(anchor, BLD + eol + anchor, 1)
    modified = True
    print('  ✓ Inserted PBXBuildFile entries')
else:
    print('  ✗ Could not find PBXBuildFile closing marker')

# 2) PBXFileReference – insert entries before closing marker
anchor = '/* End PBXFileReference section */'
if anchor in content:
    content = content.replace(anchor, REF + eol + anchor, 1)
    modified = True
    print('  ✓ Inserted PBXFileReference entries')
else:
    print('  ✗ Could not find PBXFileReference closing marker')

# 3) Models group – insert children after last child
anchor = f'{tab(4)}CC000200000000000000000B /* WebLoginModel.swift */,'
if anchor in content:
    content = content.replace(anchor, anchor + eol + GRP_MODEL, 1)
    modified = True
    print('  ✓ Inserted Models group children')
else:
    print('  ✗ Could not find Models group anchor')

# 4) Views group – insert children after last child
anchor = f'{tab(4)}CC0004000000000000000010 /* WebLoginView.swift */,'
if anchor in content:
    content = content.replace(anchor, anchor + eol + GRP_VIEW, 1)
    modified = True
    print('  ✓ Inserted Views group children')
else:
    print('  ✗ Could not find Views group anchor')

# 5) iTeamTalkTests group – insert children after last child
anchor = f'{tab(4)}254B7A621B98BAA400BE0DEF /* iTeamTalkTests.swift */,'
if anchor in content:
    content = content.replace(anchor, anchor + eol + GRP_TEST, 1)
    modified = True
    print('  ✓ Inserted iTeamTalkTests group children')
else:
    print('  ✗ Could not find iTeamTalkTests group anchor')

# 6) iTeamTalk Sources build phase – insert after last existing entry
anchor = f'{tab(4)}CC0005000000000000000010 /* WebLoginView.swift in Sources */,'
if anchor in content:
    content = content.replace(anchor, anchor + eol + SRC_IT, 1)
    modified = True
    print('  ✓ Inserted iTeamTalk Sources entries')
else:
    print('  ✗ Could not find iTeamTalk Sources anchor')

# 7) iTeamTalkTests Sources build phase – insert after last existing entry
anchor = f'{tab(4)}254B7A631B98BAA400BE0DEF /* iTeamTalkTests.swift in Sources */,'
if anchor in content:
    content = content.replace(anchor, anchor + eol + SRC_TEST, 1)
    modified = True
    print('  ✓ Inserted iTeamTalkTests Sources entries')
else:
    print('  ✗ Could not find iTeamTalkTests Sources anchor')

# ── Write back ─────────────────────────────────────────────────────────────

if modified:
    with open(PBXPROJ, 'w', encoding='utf-8', newline='') as f:
        f.write(content)
    print('\n✅ project.pbxproj updated successfully!')
else:
    print('\n❌ Nothing was modified – check errors above.')
