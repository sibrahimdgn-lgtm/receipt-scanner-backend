const test = require('node:test');
const assert = require('node:assert/strict');

const {
  buildTrendRowsWithDrilldown,
  getDashboardPeriodConfig,
  supportsTrendDrilldown,
} = require('../src/services/dashboardTrendService');

test('monthly and yearly configs expose weekly drilldown metadata', () => {
  assert.equal(getDashboardPeriodConfig('monthly').drilldownTrunc, 'week');
  assert.equal(getDashboardPeriodConfig('yearly').drilldownPeriod, 'weekly');
  assert.equal(supportsTrendDrilldown('monthly'), true);
  assert.equal(supportsTrendDrilldown('daily'), false);
});

test('attaches weekly drilldown rows to their parent monthly bucket', () => {
  const rows = buildTrendRowsWithDrilldown({
    trendRows: [{ date: '2026-04-01', total: '36463.47' }],
    drilldownRows: [
      {
        parent_date: '2026-04-01',
        date: '2026-03-30',
        label_date: '2026-04-02',
        total: '1300.98',
      },
      {
        parent_date: '2026-04-01',
        date: '2026-04-20',
        label_date: '2026-04-26',
        total: '35162.49',
      },
    ],
    supportsDrilldown: true,
  });

  assert.deepEqual(rows[0].drilldown, [
    {
      date: '2026-03-30',
      label_date: '2026-04-02',
      total: '1300.98',
    },
    {
      date: '2026-04-20',
      label_date: '2026-04-26',
      total: '35162.49',
    },
  ]);
});

test('keeps empty drilldown arrays for non-expandable trend rows', () => {
  const rows = buildTrendRowsWithDrilldown({
    trendRows: [{ date: '2026-04-28', total: '99.50' }],
  });

  assert.deepEqual(rows, [
    {
      date: '2026-04-28',
      total: '99.50',
      drilldown: [],
    },
  ]);
});
