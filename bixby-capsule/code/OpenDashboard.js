// OpenDashboard Action Handler
// 대시보드 열기 요청을 처리합니다

const endpoints = require('./endpoints.js');

module.exports.function = function openDashboard($vivContext) {
  return endpoints.OpenDashboard();
};
