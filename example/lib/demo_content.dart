/// Shared demo data for the example app.
library demo_content;

/// Default inline policy map (v2 canonical schema).
const Map<String, dynamic> kDemoPolicy = <String, dynamic>{
  'roles': <String, dynamic>{
    'admin': <String, dynamic>{
      'allowedResources': <String>[
        'dashboard',
        'settings',
        'users',
        'reports',
        'analytics',
        'admin_panel',
      ],
    },
    'manager': <String, dynamic>{
      'allowedResources': <String>[
        'dashboard',
        'reports',
        'analytics',
        'team_content',
      ],
    },
    'editor': <String, dynamic>{
      'allowedResources': <String>[
        'dashboard',
        'posts',
        'drafts',
        'published_content',
      ],
    },
    'viewer': <String, dynamic>{
      'allowedResources': <String>[
        'dashboard',
        'reports',
        'published_content',
      ],
    },
    'guest': <String, dynamic>{
      'allowedResources': <String>['dashboard'],
    },
  },
};

/// Available roles for the demo dropdowns.
const List<String> kDemoRoles = <String>[
  'admin',
  'manager',
  'editor',
  'viewer',
  'guest',
];

/// Available resources for the demo dropdowns.
const List<String> kDemoResources = <String>[
  'dashboard',
  'settings',
  'users',
  'reports',
  'analytics',
  'admin_panel',
  'posts',
  'drafts',
  'published_content',
  'team_content',
];
