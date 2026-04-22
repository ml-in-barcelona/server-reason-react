// Port of benchmark/scenarios/Dashboard.re
// Purpose: admin/dashboard UI rendering

import React from "react";
import { cx } from "./cx.js";

const StatCard = ({ title, value, change, icon, trend }) => {
  const trendColor =
    trend > 0.0 ? "text-green-500" : trend < 0.0 ? "text-red-500" : "text-gray-500";
  const trendIcon = trend > 0.0 ? "↑" : trend < 0.0 ? "↓" : "→";

  return (
    <div className="bg-white rounded-xl p-6 shadow-sm">
      <div className="flex items-center justify-between mb-4">
        <span className="text-2xl">{icon}</span>
        <span
          className={cx([
            "text-sm font-medium flex items-center gap-1",
            trendColor,
          ])}
        >
          {trendIcon}
          {`${Math.abs(trend).toFixed(1)}%`}
        </span>
      </div>
      <div>
        <h3 className="text-gray-500 text-sm font-medium">{title}</h3>
        <p className="text-3xl font-bold text-gray-900 mt-1">{value}</p>
        <p className="text-sm text-gray-500 mt-1">{change}</p>
      </div>
    </div>
  );
};

const ChartPlaceholder = ({ title, height }) => (
  <div className="bg-white rounded-xl p-6 shadow-sm">
    <h3 className="text-lg font-semibold text-gray-900 mb-4">{title}</h3>
    <div
      className="bg-gradient-to-br from-gray-50 to-gray-100 rounded-lg flex items-center justify-center"
      style={{ height: `${height}px` }}
    >
      <div className="text-center">
        <div className="text-4xl mb-2">📊</div>
        <p className="text-gray-500 text-sm">Chart visualization</p>
      </div>
    </div>
  </div>
);

const ActivityItem = ({ user, action, target, time, avatar }) => (
  <div className="flex items-start gap-4 py-4 border-b border-gray-100 last:border-0">
    <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center flex-shrink-0">
      <span className="text-lg">{avatar}</span>
    </div>
    <div className="flex-1 min-w-0">
      <p className="text-sm text-gray-900">
        <span className="font-medium">{user}</span>
        {" "}
        {action}
        {" "}
        <span className="font-medium text-blue-600">{target}</span>
      </p>
      <p className="text-xs text-gray-500 mt-1">{time}</p>
    </div>
  </div>
);

const ActivityFeed = () => {
  const activities = [
    ["Alice Chen", "updated", "Marketing Campaign Q4", "2 minutes ago", "👩"],
    ["Bob Smith", "commented on", "Product Roadmap 2024", "15 minutes ago", "👨"],
    ["Carol Davis", "completed", "User Research Report", "1 hour ago", "👩"],
    ["David Kim", "created", "New Feature Proposal", "2 hours ago", "👨"],
    ["Eve Johnson", "approved", "Budget Request #127", "3 hours ago", "👩"],
    ["Frank Wilson", "assigned", "Bug Fix #892", "4 hours ago", "🔧"],
    ["Grace Lee", "reviewed", "Code PR #456", "5 hours ago", "👩"],
    ["Henry Brown", "deployed", "v2.4.1 Release", "6 hours ago", "🚀"],
  ];

  return (
    <div className="bg-white rounded-xl shadow-sm">
      <div className="p-6 border-b border-gray-100">
        <h3 className="text-lg font-semibold text-gray-900">Recent Activity</h3>
      </div>
      <div className="px-6">
        {activities.map(([user, action, target, time, avatar], i) => (
          <ActivityItem
            key={String(i)}
            user={user}
            action={action}
            target={target}
            time={time}
            avatar={avatar}
          />
        ))}
      </div>
      <div className="p-4 border-t border-gray-100">
        <button className="text-sm text-blue-600 hover:text-blue-700 font-medium">
          View all activity →
        </button>
      </div>
    </div>
  );
};

const TopPerformers = () => {
  const performers = [
    { name: "Sarah Johnson", role: "Sales Lead", metric: 156, avatar: "👩" },
    { name: "Mike Chen", role: "Account Executive", metric: 142, avatar: "👨" },
    { name: "Emily Davis", role: "Sales Rep", metric: 128, avatar: "👩" },
    { name: "James Wilson", role: "Sales Rep", metric: 115, avatar: "👨" },
    { name: "Lisa Brown", role: "Account Executive", metric: 108, avatar: "👩" },
  ];

  return (
    <div className="bg-white rounded-xl shadow-sm">
      <div className="p-6 border-b border-gray-100">
        <h3 className="text-lg font-semibold text-gray-900">Top Performers</h3>
      </div>
      <div className="p-6">
        <div className="space-y-4">
          {performers.map((p, i) => (
            <div key={String(i)} className="flex items-center gap-4">
              <span className="text-lg text-gray-400 w-6">{`#${i + 1}`}</span>
              <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center">
                <span className="text-lg">{p.avatar}</span>
              </div>
              <div className="flex-1">
                <p className="font-medium text-gray-900">{p.name}</p>
                <p className="text-sm text-gray-500">{p.role}</p>
              </div>
              <div className="text-right">
                <p className="font-bold text-gray-900">{p.metric}</p>
                <p className="text-xs text-gray-500">deals</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

const QuickActions = () => {
  const actions = [
    ["📝", "New Report", "bg-blue-100 text-blue-600"],
    ["👥", "Add User", "bg-green-100 text-green-600"],
    ["📧", "Send Email", "bg-purple-100 text-purple-600"],
    ["📊", "Export Data", "bg-orange-100 text-orange-600"],
    ["⚙️", "Settings", "bg-gray-100 text-gray-600"],
    ["❓", "Get Help", "bg-yellow-100 text-yellow-600"],
  ];

  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
      <div className="grid grid-cols-3 gap-4">
        {actions.map(([icon, label, colors], i) => (
          <button
            key={String(i)}
            className={cx([
              "flex flex-col items-center p-4 rounded-xl transition-colors",
              colors,
              "hover:opacity-80",
            ])}
          >
            <span className="text-2xl mb-2">{icon}</span>
            <span className="text-sm font-medium">{label}</span>
          </button>
        ))}
      </div>
    </div>
  );
};

const Sidebar = ({ currentPath }) => {
  const menuItems = [
    ["🏠", "Dashboard", "/"],
    ["📊", "Analytics", "/analytics"],
    ["👥", "Users", "/users"],
    ["📦", "Products", "/products"],
    ["🛒", "Orders", "/orders"],
    ["💰", "Revenue", "/revenue"],
    ["📈", "Reports", "/reports"],
    ["⚙️", "Settings", "/settings"],
  ];

  return (
    <aside className="w-64 bg-gray-900 text-white min-h-screen flex-shrink-0">
      <div className="p-6">
        <h1 className="text-xl font-bold">📊 Dashboard</h1>
      </div>
      <nav className="px-4">
        {menuItems.map(([icon, label, path], i) => (
          <a
            key={String(i)}
            href={path}
            className={cx([
              "flex items-center gap-3 px-4 py-3 rounded-lg mb-1 transition-colors",
              path === currentPath
                ? "bg-blue-600 text-white"
                : "text-gray-400 hover:bg-gray-800 hover:text-white",
            ])}
          >
            <span className="text-lg">{icon}</span>
            <span className="font-medium">{label}</span>
          </a>
        ))}
      </nav>
      <div className="absolute bottom-0 left-0 w-64 p-4 border-t border-gray-800">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-gray-700 flex items-center justify-center">
            <span>👤</span>
          </div>
          <div>
            <p className="font-medium text-sm">Admin User</p>
            <p className="text-xs text-gray-400">admin@company.com</p>
          </div>
        </div>
      </div>
    </aside>
  );
};

const Header = () => (
  <header className="bg-white border-b border-gray-200 px-8 py-4">
    <div className="flex items-center justify-between">
      <div>
        <h2 className="text-2xl font-bold text-gray-900">Dashboard Overview</h2>
        <p className="text-gray-500 text-sm">Welcome back! Here's what's happening.</p>
      </div>
      <div className="flex items-center gap-4">
        <div className="relative">
          <input
            type="search"
            placeholder="Search..."
            className="pl-10 pr-4 py-2 border border-gray-200 rounded-lg text-sm w-64"
          />
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">🔍</span>
        </div>
        <button className="p-2 text-gray-500 hover:text-gray-700 relative">
          🔔
          <span className="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full" />
        </button>
        <button className="p-2 text-gray-500 hover:text-gray-700">⚙️</button>
      </div>
    </div>
  </header>
);

export const Dashboard = () => (
  <html lang="en">
    <head>
      <meta charSet="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>Analytics Dashboard</title>
    </head>
    <body className="bg-gray-100">
      <div className="flex">
        <Sidebar currentPath="/" />
        <div className="flex-1">
          <Header />
          <main className="p-8">
            <div className="grid grid-cols-4 gap-6 mb-8">
              <StatCard title="Total Revenue" value="$284,532" change="vs last month" icon="💰" trend={12.5} />
              <StatCard title="Active Users" value="14,832" change="vs last month" icon="👥" trend={8.2} />
              <StatCard title="Total Orders" value="3,427" change="vs last month" icon="📦" trend={-2.4} />
              <StatCard title="Conversion Rate" value="3.24%" change="vs last month" icon="📈" trend={0.8} />
            </div>
            <div className="grid grid-cols-2 gap-6 mb-8">
              <ChartPlaceholder title="Revenue Over Time" height={300} />
              <ChartPlaceholder title="User Growth" height={300} />
            </div>
            <div className="grid grid-cols-3 gap-6">
              <div className="col-span-2">
                <ActivityFeed />
              </div>
              <div className="space-y-6">
                <TopPerformers />
                <QuickActions />
              </div>
            </div>
          </main>
        </div>
      </div>
    </body>
  </html>
);
