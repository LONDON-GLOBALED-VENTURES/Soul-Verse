import os
import json
import sys

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(ROOT_DIR, 'backend'))

from scripts.generate_verses import curated_targets, book_names, books_map

VALID_MOODS = {"anxious", "hopeful", "grateful", "sad", "stressed", "need-strength", "lost", "joyful"}

# 1. Load existing verses
verses_path = os.path.join(ROOT_DIR, 'backend', 'src', 'data', 'verses.json')
with open(verses_path, 'r', encoding='utf-8') as f:
    existing_verses = json.load(f)

print(f"Loaded {len(existing_verses)} existing verses.")
existing_refs = set(v['reference'].lower() for v in existing_verses)
existing_ids = set(v['id'] for v in existing_verses)

# 2. Extract unique candidates from curated targets
seen_refs = set(existing_refs)
seen_ids = set(existing_ids)
valid_candidates = []

for item in curated_targets:
    abbrev, ch, v, moods, refl = item
    if abbrev not in book_names:
        continue
    full_name, id_prefix = book_names[abbrev]
    ref = f"{full_name} {ch}:{v}"
    ref_lower = ref.lower()
    
    if ref_lower in seen_refs:
        continue
        
    b = books_map.get(abbrev)
    if not b or ch - 1 >= len(b['chapters']) or v - 1 >= len(b['chapters'][ch - 1]):
        print(f"Warning: Missing text for {ref}")
        continue
        
    text = b['chapters'][ch - 1][v - 1].strip()
    vid = f"{id_prefix}-{ch}-{v}"
    
    if vid in seen_ids:
        print(f"Warning: Duplicate id {vid}")
        continue
        
    seen_refs.add(ref_lower)
    seen_ids.add(vid)
    valid_candidates.append({
        'id': vid,
        'text': text,
        'reference': ref,
        'translation': 'KJV',
        'moods': moods,
        'reflection': refl
    })

print(f"Found {len(valid_candidates)} unique new candidates.")

# 3. We need exactly 500 total, which means 500 - 47 = 453 new verses.
needed_new = 500 - len(existing_verses)
print(f"Target total: 500. Needed new: {needed_new}.")

if len(valid_candidates) > needed_new:
    excess = len(valid_candidates) - needed_new
    print(f"Trimming {excess} excess candidates to reach exactly {needed_new} new verses...")
    
    # Prioritize keeping verses that support lower-frequency moods (anxious, stressed, sad)
    # Sort candidates so that those with only 'hopeful' or over-represented moods can be trimmed first
    def trim_score(v):
        # Lower score = keep first; higher score = can be trimmed first
        score = 0
        if 'anxious' in v['moods']:
            score -= 10
        if 'stressed' in v['moods']:
            score -= 10
        if 'sad' in v['moods']:
            score -= 10
        if 'joyful' in v['moods']:
            score -= 5
        if 'hopeful' in v['moods']:
            score += 15
        if 'grateful' in v['moods']:
            score += 5
        return score

    # Sort so items with highest score (safest to drop) are at the end
    valid_candidates.sort(key=trim_score)
    selected_new = valid_candidates[:needed_new]
elif len(valid_candidates) == needed_new:
    selected_new = valid_candidates
else:
    raise ValueError(f"Not enough candidates! Only {len(valid_candidates)} available, needed {needed_new}.")

final_500 = existing_verses + selected_new

# 4. Strict Validation
assert len(final_500) == 500, f"Expected exactly 500 verses, got {len(final_500)}"

id_set = set()
ref_set = set()
mood_distribution = {m: 0 for m in VALID_MOODS}

for i, v in enumerate(final_500):
    # Check original verses intact
    if i < len(existing_verses):
        assert v == existing_verses[i], f"Original verse {i} was altered!"
    
    # Check fields
    assert 'id' in v and v['id'], f"Missing id at {i}"
    assert 'text' in v and len(v['text']) > 5, f"Missing/short text at {i}: {v}"
    assert 'reference' in v and v['reference'], f"Missing reference at {i}"
    assert v.get('translation') == 'KJV', f"Invalid translation at {i}: {v.get('translation')}"
    assert 'moods' in v and len(v['moods']) >= 1, f"Missing moods at {i}"
    assert 'reflection' in v and len(v['reflection']) > 10, f"Missing/short reflection at {i}"
    
    # Check ID uniqueness
    assert v['id'] not in id_set, f"Duplicate id: {v['id']}"
    id_set.add(v['id'])
    
    # Check Reference uniqueness
    ref_norm = v['reference'].lower()
    assert ref_norm not in ref_set, f"Duplicate reference: {v['reference']}"
    ref_set.add(ref_norm)
    
    # Check moods validity
    for m in v['moods']:
        assert m in VALID_MOODS, f"Invalid mood '{m}' in verse {v['id']}"
        mood_distribution[m] += 1

print("\n--- VALIDATION PASSED ---")
print(f"Total verses: {len(final_500)}")
print(f"Unique IDs: {len(id_set)}")
print(f"Unique References: {len(ref_set)}")
print("\nMood Distribution across all 500 verses:")
for m, c in sorted(mood_distribution.items(), key=lambda x: x[1], reverse=True):
    print(f"  {m:15}: {c} verses")

# 5. Write to backend/src/data/verses.json
with open(verses_path, 'w', encoding='utf-8') as f:
    json.dump(final_500, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f"\nSuccessfully wrote 500 verses to {verses_path}")
