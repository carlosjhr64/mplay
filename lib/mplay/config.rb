module Mplay
  using Rafini::String

  APPDIR = File.dirname File.dirname __dir__

  a0 = Rafini::Empty::ARRAY
  h0 = Rafini::Empty::HASH
  s0 = Rafini::Empty::STRING

  DAY = 60*60*24

  CONFIG = {

    Running: 'Running...',
    Done:    'Done!',
    NotUrl:  'Not a url.',
    Wait:    'Need to wait for current download',
    Ln:      'Hard linked.',
    Cp:      'Copied.',
    Cancel:  'Cancel current download?',

    SEARCH_FIELDS: ['description','title'],

    Max: 100,
    Sleep: 750,

    # My guess is youtube expires video urls in 6 hours, and so
    # 4 hours seems like a reasonable data cache time.
    Expire: 60*60*4,

    UrlMatch: '\Ahttps?:\/\/\S+\Z',
    SmallFont: 'Courier 8',

    Blue: '#00F',
    Red:  '#F00',

    Downloading: "#{XDG['DATA']}/gtk3app/mplay/downloading.png",
    Playing: "#{XDG['DATA']}/gtk3app/mplay/playing.png",
    High: "#{XDG['DATA']}/gtk3app/mplay/high.png",
    Low: "#{XDG['DATA']}/gtk3app/mplay/low.png",

    # Prefered Resolutions
    LowWidth:   400,
    LowHeight:  240,
    MedWidth:   640,
    MedHeight:  360,
    HghWidth:  1280,
    HghHeight:  720,

    PREFERED_EXT: ['mp4', 'flv'],
    PREFERED_FID:  ['5','18','22'],

    Mplayer: "mplayer -really-quiet '$1' > /dev/null 2>&1 &",
    Wget: "wget --no-verbose -O '$2' '$1'",
    Tee: "wget --no-verbose -O - '$1' | " +
         "tee '$2' | " +
         "mplayer -really-quiet -cache 65535 -cache-min 1 - 2> /dev/null; " +
         "exit ${PIPESTATUS[0]}",

    URL_LABELS:   ['Url: ', 'http://', 'Go'],
    COMBO_LABELS: ['Format:', 0, 'Play'],

    Download: 'Download',
    Export: 'Export',
    ExportDirectory: "#{ENV['HOME']}/Videos",

    WebPage: 'Web',

    thing: {
      tight: {
        into: [:pack_start, expand: false, fill: false, padding: 1],
      },
      expansive: {
        into: [:pack_start, expand: true, fill: true, padding: 1],
      },

      box: h0,
      vbox!: [[:vertical],   :box, s0],
      hbox!: [[:horizontal], :tight, :box, s0],

      label: {
        set_wrap: true,
        set_alignment: [0.0, 0.5],
      },
      title_label!: [:tight, :label],

      prompt!: [a0, :tight, :label, s0],

      active: {
        set_width_request: 375,
      },
      active!: [a0, :active, 'activate'],

      click: h0,
      click!: [a0, :tight, :click, 'clicked'],

      combo: h0,
      combo!: [a0, :tight, :combo, 'changed'],

      error_label!: [:tight, :label],

      l!: [[label: 'Low'], 'activate'],
      m!: [[label: 'Medium'], 'activate'],
      h!: [[label: 'High'], 'activate'],

      RELOAD: ['Reload'],
      reload: h0,

      window: {
        set_title: 'Mplay',
        set_window_position: :center,
      },

      scroll!: a0,

      question_dialog: {
        set_title: 'Question',
        set_window_position: :center_on_parent,
      },
      question_label!: [:tight, :label],

      export_dialog: {
        set_title: 'Export',
        set_window_position: :center_on_parent,
      },

      about_dialog: {
        set_program_name: 'Mplay',
        set_version: VERSION.semantic(0..1),
        set_copyright: '(c) 2017 CarlosJHR64',
        set_comments: 'A Gtk3App YouTube-DL Mplayer Manager',
        set_website: 'https://github.com/carlosjhr64/mplay',
        set_website_label: 'See it at GitHub!',
      },
      HelpFile: 'https://github.com/carlosjhr64/mplay',
      Logo: "#{XDG['DATA']}/gtk3app/mplay/logo.png",
    },

    TITLE: ['stitle', 'title', 'fulltitle'],
    NoTitle: '* * *',
  }
end
