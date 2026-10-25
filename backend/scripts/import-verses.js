/**
 * Adds verses for one emotion to src/data/verses.json.
 *
 *   node scripts/import-verses.js <moodId> <file.txt> [translation]
 *
 * The file has one verse per line: `Psalm 34:18: “The LORD is near…”`
 * (blank lines and the emotion heading are ignored). A verse that already
 * exists (same reference) gets the emotion added instead of being duplicated.
 */
const fs = require('fs');
const path = require('path');

const VERSES_FILE = path.join(__dirname, '..', 'src', 'data', 'verses.json');
const MOODS_FILE = path.join(__dirname, '..', 'src', 'data', 'moods.json');

// "1 Samuel 1:10: “text”" or "Psalm 13:1-2: "text"" (curly or straight quotes).
const LINE = /^(.+?\s\d+:\d+(?:-\d+)?):\s*[“"](.+)[”"]\s*$/;

const idFor = (reference) =>
  reference.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

/** Returns { verses, skipped } where skipped are non-blank lines that aren't verses. */
const parseVerses = (text) => {
  const verses = [];
  const skipped = [];
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (!line) continue;
    const match = LINE.exec(line);
    if (match) verses.push({ reference: match[1].trim(), text: match[2].trim() });
    else skipped.push(line);
  }
  return { verses, skipped };
};

/** Merges parsed verses into [existing] for [moodId]; returns counts. Mutates [existing]. */
const mergeVerses = (existing, parsed, moodId, translation) => {
  let added = 0;
  let tagged = 0;
  let unchanged = 0;
  for (const { reference, text } of parsed) {
    const id = idFor(reference);
    const current = existing.find((v) => v.id === id);
    if (!current) {
      existing.push({ id, text, reference, translation, moods: [moodId], reflection: '' });
      added++;
    } else if (!current.moods.includes(moodId)) {
      current.moods.push(moodId);
      tagged++;
    } else {
      unchanged++;
    }
  }
  return { added, tagged, unchanged };
};

const main = () => {
  const [moodId, file, translation = 'WEB'] = process.argv.slice(2);
  if (!moodId || !file) {
    console.error('Usage: node scripts/import-verses.js <moodId> <file.txt> [translation]');
    process.exit(1);
  }
  const moods = JSON.parse(fs.readFileSync(MOODS_FILE, 'utf8'));
  if (!moods.some((m) => m.id === moodId)) {
    console.error(`Unknown emotion "${moodId}". Known: ${moods.map((m) => m.id).join(', ')}`);
    process.exit(1);
  }

  const { verses, skipped } = parseVerses(fs.readFileSync(file, 'utf8'));
  const existing = JSON.parse(fs.readFileSync(VERSES_FILE, 'utf8'));
  const counts = mergeVerses(existing, verses, moodId, translation);
  fs.writeFileSync(VERSES_FILE, `${JSON.stringify(existing, null, 2)}\n`, 'utf8');

  console.log(
    `${moodId}: ${counts.added} added, ${counts.tagged} existing verses tagged, ` +
      `${counts.unchanged} already there. Total verses: ${existing.length}.`,
  );
  if (skipped.length) {
    console.log(`Skipped ${skipped.length} line(s) that aren't verses:`);
    for (const line of skipped) console.log(`  ${line}`);
  }
};

if (require.main === module) main();

module.exports = { parseVerses, mergeVerses, idFor };
