const DEFAULT_PERIOD = 'daily';

const PERIODS = {
  daily: { trunc: 'day', interval: '7 days' },
  weekly: { trunc: 'week', interval: '1 month' },
  monthly: {
    trunc: 'month',
    interval: '6 months',
    drilldownTrunc: 'week',
    drilldownPeriod: 'weekly',
  },
  yearly: {
    trunc: 'year',
    interval: '5 years',
    drilldownTrunc: 'week',
    drilldownPeriod: 'weekly',
  },
};

function getDashboardPeriodConfig(period) {
  return PERIODS[period] || PERIODS[DEFAULT_PERIOD];
}

function supportsTrendDrilldown(period) {
  const config = getDashboardPeriodConfig(period);
  return Boolean(config.drilldownTrunc && config.drilldownPeriod);
}

function normalizeSqlDate(value) {
  if (!value) {
    return null;
  }

  const text = value.toString();
  return text.length >= 10 ? text.slice(0, 10) : text;
}

function buildTrendRowsWithDrilldown({
  trendRows = [],
  drilldownRows = [],
  supportsDrilldown = false,
}) {
  if (!supportsDrilldown) {
    return trendRows.map((row) => ({
      ...row,
      date: normalizeSqlDate(row.date),
      drilldown: [],
    }));
  }

  const drilldownMap = new Map();
  for (const row of drilldownRows) {
    const parentDate = normalizeSqlDate(row.parent_date);
    if (!parentDate) {
      continue;
    }

    if (!drilldownMap.has(parentDate)) {
      drilldownMap.set(parentDate, []);
    }

    drilldownMap.get(parentDate).push({
      date: normalizeSqlDate(row.date),
      label_date: normalizeSqlDate(row.label_date || row.date),
      total: row.total,
    });
  }

  return trendRows.map((row) => {
    const parentDate = normalizeSqlDate(row.date);
    const drilldown = (drilldownMap.get(parentDate) || []).sort((a, b) =>
      (a.date || '').localeCompare(b.date || '')
    );

    return {
      ...row,
      date: parentDate,
      drilldown,
    };
  });
}

module.exports = {
  buildTrendRowsWithDrilldown,
  getDashboardPeriodConfig,
  supportsTrendDrilldown,
};
