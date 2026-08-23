import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'ZoomacIt',
  description: 'A native macOS menu bar app inspired by ZoomIt for Windows',
  base: '/ZoomacIt/',

  head: [
    ['link', { rel: 'icon', href: '/ZoomacIt/images/icon-36.png' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: 'ZoomacIt' }],
    ['meta', { property: 'og:description', content: 'Mac-native screen zoom, draw, snip, and annotation tool with AI' }],
    ['meta', { property: 'og:image', content: 'https://yusufk.github.io/ZoomacIt/images/banner.png' }],
    ['meta', { property: 'og:url', content: 'https://yusufk.github.io/ZoomacIt/' }],
  ],

  locales: {
    root: {
      label: 'English',
      lang: 'en',
      themeConfig: {
        nav: [
          { text: 'Installation', link: '/installation' },
          { text: 'Usage', link: '/usage' },
        ],
        sidebar: [
          {
            text: 'Guide',
            items: [
              { text: 'Installation', link: '/installation' },
              {
                text: 'Usage',
                link: '/usage',
                items: [
                  { text: 'Zoom', link: '/usage/zoom' },
                  { text: 'Draw', link: '/usage/draw' },
                  { text: 'Snip', link: '/usage/snip' },
                  { text: 'AI Snip', link: '/usage/ai-snip' },
                  { text: 'Record', link: '/usage/record' },
                  { text: 'DemoType', link: '/usage/demo-type' },
                  { text: 'Break Timer', link: '/usage/break-timer' },
                ],
              },
            ],
          },
        ],
      },
    },
    ja: {
      label: '日本語',
      lang: 'ja',
      description: 'Windows ZoomIt にインスパイアされたネイティブ macOS メニューバーアプリ',
      themeConfig: {
        nav: [
          { text: 'インストール', link: '/ja/installation' },
          { text: '使い方', link: '/ja/usage' },
        ],
        sidebar: [
          {
            text: 'ガイド',
            items: [
              { text: 'インストール', link: '/ja/installation' },
              {
                text: '使い方',
                link: '/ja/usage',
                items: [
                  { text: 'ズーム', link: '/ja/usage/zoom' },
                  { text: 'ドロー', link: '/ja/usage/draw' },
                  { text: 'スニップ', link: '/ja/usage/snip' },
                  { text: 'レコード', link: '/ja/usage/record' },
                  { text: 'デモタイプ', link: '/ja/usage/demo-type' },
                  { text: '休憩タイマー', link: '/ja/usage/break-timer' },
                ],
              },
            ],
          },
        ],
        outline: { label: '目次' },
        docFooter: { prev: '前のページ', next: '次のページ' },
        lastUpdated: { text: '最終更新' },
        returnToTopLabel: 'トップに戻る',
        darkModeSwitchLabel: 'テーマ',
        langMenuLabel: '言語',
      },
    },
  },

  themeConfig: {
    logo: '/images/icon-36.png',

    socialLinks: [
      { icon: 'github', link: 'https://github.com/yusufk/ZoomacIt' },
    ],

    search: {
      provider: 'local',
    },

    footer: {
      message: 'Released under the GPL-3.0 License.',
      copyright: '© 2026 <a href="https://github.com/yusufk">Yusuf Kaka</a> · Originally by <a href="https://github.com/07JP27">07JP27</a>',
    },
  },
})
