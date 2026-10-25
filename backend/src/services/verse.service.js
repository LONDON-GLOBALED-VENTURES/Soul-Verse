let verses = require('../data/verses.json');
const moodService = require('./mood.service');
const templateService = require('./template.service');
const HttpError = require('../utils/http-error');

const DAY_MS = 24 * 60 * 60 * 1000;
const MAX_RANGE_DAYS = 31;

const list = ({ mood } = {}) => {
  if (!mood) return verses;
  moodService.assertExists(mood);
  return verses.filter((verse) => verse.moods.includes(mood));
};

/** Validates a YYYY-MM-DD calendar date and returns it as a UTC-midnight Date. */
const parseDate = (value, name = 'date') => {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value ?? '');
  const date = match && new Date(Date.UTC(+match[1], +match[2] - 1, +match[3]));
  // Rejects impossible dates like 2026-02-30, which Date would silently roll over.
  if (!date || date.toISOString().slice(0, 10) !== value) {
    throw new HttpError(400, `Invalid ${name}: expected YYYY-MM-DD`);
  }
  return date;
};

const toDateString = (date) => date.toISOString().slice(0, 10);

const todayUtc = () => toDateString(new Date());

// Based on the calendar date, so everyone sees the same verse on the same local date.
const dayIndex = (date) => Math.floor(date.getTime() / DAY_MS);

/** The verse and background for one calendar date (YYYY-MM-DD). */
const getDaily = (dateString = todayUtc()) => {
  const date = parseDate(dateString);
  if (verses.length === 0) throw new HttpError(404, 'No verses available yet');
  const index = dayIndex(date);
  return {
    date: toDateString(date),
    verse: verses[index % verses.length],
    template: templateService.getForDay(index),
  };
};

/** Consecutive daily entries starting at [start], e.g. for scheduling reminders. */
const getDailyRange = (start, days) => {
  const first = parseDate(start, 'start');
  const count = Number(days);
  if (!Number.isInteger(count) || count < 1 || count > MAX_RANGE_DAYS) {
    throw new HttpError(400, `Invalid days: expected 1-${MAX_RANGE_DAYS}`);
  }
  if (verses.length === 0) return [];
  return Array.from({ length: count }, (_, i) =>
    getDaily(toDateString(new Date(first.getTime() + i * DAY_MS))),
  );
};

const _setVersesForTests = (list) => {
  verses = list;
};

module.exports = { list, getDaily, getDailyRange, MAX_RANGE_DAYS, _setVersesForTests };
