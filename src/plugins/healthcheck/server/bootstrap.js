'use strict';

module.exports = ({ strapi }) => {
  const routes = [
    {
      method: 'GET',
      path: `/health`,
      handler: (ctx) => {
        ctx.body = { "status": "ok", "message": "All engines running 🚀" };
      }
    }
  ];

  routes.forEach(route => {
    route.info = { pluginName: 'healthcheck' };
    route.config = {
      auth: false
    };
  });

  strapi.server.routes({
    type: 'admin',
    routes
  });
}; 