const { test } = require('node:test');
const assert = require('node:assert/strict');
const { parseVerses, mergeVerses, idFor } = require('../scripts/import-verses');

test('parses references with numbered books, ranges and curly quotes', () => {
  const { verses, skipped } = parseVerses(
    [
      'Heartbroken',
      '',
      '1 Samuel 1:10: “She was in bitterness of soul.”',
      'Psalm 13:1-2: “How long, LORD? Will you forget me forever?”',
      'John 11:35: "Jesus wept."',
      'Psalm 42:3: “…they continually ask me, ‘Where is your God?’”',
    ].join('\r\n'),
  );

  assert.deepEqual(
    verses.map((v) => v.reference),
    ['1 Samuel 1:10', 'Psalm 13:1-2', 'John 11:35', 'Psalm 42:3'],
  );
  assert.equal(verses[1].text, 'How long, LORD? Will you forget me forever?');
  assert.equal(verses[3].text, '…they continually ask me, ‘Where is your God?’');
  assert.deepEqual(skipped, ['Heartbroken']);
});

test('ids come from the reference', () => {
  assert.equal(idFor('1 Samuel 1:10'), '1-samuel-1-10');
  assert.equal(idFor('Psalm 13:1-2'), 'psalm-13-1-2');
});

test('a verse already in another emotion gets tagged, not duplicated', () => {
  const existing = [
    {
      id: 'psalm-34-18',
      text: 'The LORD is near…',
      reference: 'Psalm 34:18',
      translation: 'WEB',
      moods: ['sadness'],
      reflection: 'Kept as is.',
    },
  ];
  const parsed = [
    { reference: 'Psalm 34:18', text: 'The LORD is near…' },
    { reference: 'Psalm 147:3', text: 'He heals the broken in heart.' },
  ];

  const first = mergeVerses(existing, parsed, 'heartbroken', 'WEB');
  const again = mergeVerses(existing, parsed, 'heartbroken', 'WEB');

  assert.deepEqual(first, { added: 1, tagged: 1, unchanged: 0 });
  assert.deepEqual(again, { added: 0, tagged: 0, unchanged: 2 });
  assert.equal(existing.length, 2);
  assert.deepEqual(existing[0].moods, ['sadness', 'heartbroken']);
  assert.equal(existing[0].reflection, 'Kept as is.');
  assert.deepEqual(existing[1], {
    id: 'psalm-147-3',
    text: 'He heals the broken in heart.',
    reference: 'Psalm 147:3',
    translation: 'WEB',
    moods: ['heartbroken'],
    reflection: '',
  });
});
