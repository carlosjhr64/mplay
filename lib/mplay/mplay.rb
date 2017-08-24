module Mplay
  def self.run(program)
    Mplay.new(program)
  end

  class QuestionDialog < Such::Dialog
    def initialize(question, parent=nil)
      super([parent: parent], :question_dialog)
      # We were given parent, but it's not visible.
      # Then set centered on parent is nonsense.
      # So override to :center in that case.
      set_window_position(:center) if parent and !parent.visible?
      add_button('_No', Gtk::ResponseType::CANCEL)
      add_button('_Yes', Gtk::ResponseType::OK)
      Such::Label.new(child, :question_label!).text = question
    end

    def runs
      show_all
      value = false
      if run == Gtk::ResponseType::OK
        value = true
      end
      destroy
      return value
    end
  end

  class ExportDialog < Such::FileChooserDialog
    def initialize(parent, basename)
      super([parent: parent], :export_dialog)
      set_action Gtk::FileChooser::Action::SAVE
      add_button(Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL)
      add_button(Gtk::Stock::OPEN, Gtk::ResponseType::ACCEPT)
      set_current_folder CONFIG[:ExportDirectory]
      set_current_name basename
    end

    def runs
      show_all
      value = nil
      if run == Gtk::ResponseType::ACCEPT
       value = filename
      end
      destroy
      return value
    end
  end

  class DownloadButton < Such::Button
    def relabel(cache)
      self.label = (File.exist?(cache))? CONFIG[:Export] : CONFIG[:Download]
    end
  end

  class Combo < Such::LabelComboButton
    def selects(arr)
      arr[self.combo_ComboBoxText.active]
    end
    def appends(formats)
      formats.each do |format|
        self.combo_ComboBoxText.append_text format
      end
    end
  end

  class Mplay
    using Rafini::Exception
    using Rafini::Array
    using Rafini::Hash
    using Rafini::Odometers

    cache = File.join XDG['CACHE'].to_s, 'gtk3app', 'mplay'
    DB = File.join cache, 'db'
    VD = File.join cache, 'vd'

    H2W = BaseConvert::FromTo.new(:hex, :word)

    def self.db(url)
      # Don't need the http: or https: part.
      key = H2W.convert Digest::MD5.hexdigest url.sub(/^.*:/,'')
      File.join DB, key
    end

    # cache = Mplay.vd(host,id,fid,ext) #=> "#{host}:#{id},#{fid}.#{ext}"
    def self.vd(*p)
      File.join VD, p.joins(':',','){'.'}
    end

    # Note:
    #   There's no guarantee that there won't be a video id collision from different sources.
    #   But as used so far, collisions results in either no effect or no damage.
    #   Just be aware of the issue in further work with it.
    def self.vds
      Find.find(VD) do |vd|
        if vd=~/:([^,]+),/
          yield vd, $1
        end
      end
    end

    def self.cached(cached={})
      Mplay.vds{|vd,id|cached[id]=true}
      return cached
    end

    def self.score(obj, cached)
      c = obj['view_count'].to_f + 1.0
      l = obj['like_count'].to_f + 1.0
      t = l + obj['dislike_count'].to_f + 1.0
      r = l/t
      d = obj['upload_date']
      d = (Date.today - Date.parse(d)).to_i  if d
      f = 1.0
      f += Math.exp(-d/365.25)  if d
      s = f*r*Math.log(c*t)
      s *= 100.0 if cached[obj['id']]
      return s
    end

    def self.dbs
      Find.find(DB) do |db|
        if db=~/\/[^_\W]+$/ and File.file?(db)
          yield db
        end
      end
    end

    def self.sorted_db_keys
      dbs = []
      Mplay.dbs do |db|
        dbs.push([File.basename(db), File.mtime(db)])
      end
      # Sorted by latest first
      dbs.sort{|a,b|b[1]<=>a[1]}.map{|_|_[0]}
    end

    def self.sorted_dbs
      Mplay.sorted_db_keys.each{|key|yield(File.join(DB, key))}
    end

    def self.videos_from_search(string)
      # Get the key words
      specials = nil
      keys = string.downcase.split(/[^:\w]+/).uniq
      if keys.length == 0
        keys = nil
      else
        specials = keys.select{|_|_=~/:/}.map{|_|_.split(/:/)}
        keys.delete_if{|_|_=~/:/}
      end
      # Data hashes
      cached = Mplay.cached
      matched, scores, reject = {}, {}, {}
      # If selection exceeds maximum allowed,
      # keep track of score to determine entry.
      min, low = 0.0, nil
      Mplay.sorted_dbs do |db|
        begin
          list = JSON.parse File.read db
          list.each do |obj|
            id = obj['id']
            next if reject[id] or matched[id] # seen this one already
            scr = Mplay.score(obj, cached)
            # Ties not likely, but don't have a better way to break ties
            # other than which was accepted first.
            if scr <= min
              reject[id] = true # Too low a score.
              next
            end
            if keys.nil? or Mplay.accept?(obj, keys, specials)
              matched[id] = obj
              scores[id] = scr
            else
              reject[id] = true # No match.
              next
            end
            if matched.length > CONFIG[:Max]
              # This candidate was better than min, so start from there.
              newmin = min = scr
              scores.each do |i,s|
                if s < min
                  newmin = min # This min new threshold
                  min = s # This min going out
                  low = i
                end
              end
              min = newmin # OK, this is the new min.
              scores.delete(low)
              matched.delete(low)
              reject[low] = true # Washed out.
            end
          end
        rescue StandardError
          $!.puts # :-??
        end
      end
      matched.keys.sort{|id1,id2|scores[id2]<=>scores[id1]}.map{|id|matched[id]}
    end

    def self.accept?(obj, keys, specials)
      specials.each do |field, key|
        return false unless obj[field].to_s.downcase.include?(key)
      end
      words = CONFIG[:SEARCH_FIELDS].map{|field|obj[field].to_s.downcase.split(/\W+/).uniq}.flatten.uniq
      keys.each do |key|
        return false unless words.include?(key)
      end
      return true
    end

    def self.info(obj)
      label = ''

      d = nil
      if upload_date = obj['upload_date']
        d = (Date.today - Date.parse(upload_date)).to_i
        timeago = (d*86400).sec2time.to_s # *(24*60*60)
        label += "Uploaded #{timeago} ago. "
      end

      if duration = obj['duration']
        label += "#{duration.sec2time} long. "
      end

      c = nil
      if view_count = obj['view_count']
        c = view_count + 1
        label += "#{view_count.illion} views. "
      end

      l = t = r = nil
      if like_count = obj['like_count'] and dislike_count = obj['dislike_count']
        l = like_count + 1
        t = l + dislike_count + 1
        r = l.to_f/t.to_f
        label += "#{(r*100).round(0)}% liked. "
      end

      scr = 0.0
      if d and c and r and t
        fresh = 1.0 + Math.exp(-d/365.25) # Fresh factor
        scr = fresh*r*Math.log(c*t)
        label += "Scored #{scr.round(1)}."
      end

      return label
    end

    def self.host_and_id(obj)
      [URI.parse(obj['webpage_url']).host, obj['id']]
    end

    def fitness(a)
      w = @prefered_width  - a['width'].to_i
      h = @prefered_height - a['height'].to_i
      e = (CONFIG[:PREFERED_EXT].include?(a['ext']))?       1 : 0
      f = (CONFIG[:PREFERED_FID].include?(a['format_id']))? 1 : 0
      c = a[:CACHED]? 1 : 0
      r = (e + f + c) + 1.0 / (1.0 + (w*w + h*h))
      return r
    end

    def self.generic(url, cache, key)
      cmd = CONFIG[key].dup
      cmd.gsub!(/\$1/, url)
      cmd.gsub!(/\$2/, cache) if cache
      $stderr.puts cmd if $VERBOSE
      unless system cmd
        $stderr.puts "Command did not complete." if $VERBOSE
        if cache
          $stderr.puts "Deleting #{cache}." if $VERBOSE
          File.unlink cache
        end
        return false
      end
      return true
    end

    def self.mplayer(cache)
      Mplay.generic(cache,  nil, :Mplayer)
    end

    def self.tee(url, cache)
      Mplay.generic(url, cache, :Tee)
    end

    def self.wget(url, cache)
      Mplay.generic(url, cache, :Wget)
    end

    def self.trim
      cached = Mplay.cached
      Mplay.dbs do |db|
        delete = true # Maybe we delete?
        JSON.parse(File.read(db)).each do |obj|
          if cached[obj['id']]
            delete = false # Nah! We need it still.
            break
          end
        end
        File.unlink(db) if delete
      end
    end

    def self.old(old)
      expired = Time.now - DAY*old
      Mplay.vds{|vd, _| File.unlink(vd)  if File.atime(vd) < expired}
    end

    def self.limit(limit)
      caching = Mplay.cached
      if caching.length > limit
        Mplay.vds do |vd, id|
          # When did we last watch the files we're caching?
          # The "if" is just in case something was added just now.
          caching[id] = File.atime(vd) if caching[id]
        end
        # And just in case something was deleted just now.
        caching.delete_if{|x|x==true}
        old = caching.values.sort[-limit]
        caching.delete_if{|id,t|t<old}
        Mplay.vds do |vd, id|
          # So delete any files we're not caching.
          File.unlink(vd) unless caching[id]
        end
      end
    end

    # Video formats are immediately sorted when first received
    # so the first format is the preferred download.
    # Assume that this is the one to cache.
    def self.cached_video?(obj)
      if formats = obj['formats']
        fid, ext = formats.first.maps('format_id', 'ext')
        host, id = Mplay.host_and_id(obj)
        cache = Mplay.vd(host, id, fid, ext)
        return File.exist?(cache)
      end
      return false
    end

    def self.expired?(cache)
      (Time.now - File.mtime(cache)).to_i > CONFIG[:Expire]
    end

    def initialize(program)
      Dir.mkdir DB unless File.exist? DB
      Dir.mkdir VD unless File.exist? VD

      @doit_thread = @download_thread = @download_cache = @playit_thread = @scroll = nil

      @small_font = Pango::FontDescription.new CONFIG[:SmallFont]
      @blue = Gdk::RGBA.parse(CONFIG[:Blue])
      @red  = Gdk::RGBA.parse(CONFIG[:Red])

      @icon = program.mini.children.first
      @ready = ready = @icon.pixbuf
      @downloading = GdkPixbuf::Pixbuf.new(file: CONFIG[:Downloading])
      @playing = GdkPixbuf::Pixbuf.new(file: CONFIG[:Playing])
      @high = GdkPixbuf::Pixbuf.new(file: CONFIG[:High])
      @low = GdkPixbuf::Pixbuf.new(file: CONFIG[:Low])

      @auto = false
      @cancel = false

      @window = program.window
      @vbox = Such::Box.new @window, :vbox!

      @url = Such::LabelEntryButton.new(@vbox, :hbox!){doit}
      @url.labels(*CONFIG[:URL_LABELS])
      @reload = Such::CheckButton.new @url, :reload!
      @reload.override_font @small_font
      @reload.override_color :normal, @blue

      cbt = Such::ComboBoxText.new(@url,'changed') do
        case cbt.active_text
        when 'l'
          @prefered_width  = CONFIG[:LowWidth]
          @prefered_height = CONFIG[:LowHeight]
          @ready = @low
          @icon.set_pixbuf @ready
        when 'm'
          @prefered_width  = CONFIG[:MedWidth]
          @prefered_height = CONFIG[:MedHeight]
          @ready = ready
          @icon.set_pixbuf @ready
        when 'h'
          @prefered_width  = CONFIG[:HghWidth]
          @prefered_height = CONFIG[:HghHeight]
          @ready = @high
          @icon.set_pixbuf @ready
        end
      end
      cbt.append_text 'l'
      cbt.append_text 'm'
      cbt.append_text 'h'
      cbt.set_active(1)

      @url_match = Regexp.new(CONFIG[:UrlMatch])

      @error = Such::Label.new @vbox, :error_label!
      @error.override_font @small_font
      @error.override_color :normal, @blue

      @clipboard = nil
      GLib::Timeout.add(CONFIG[:Sleep]){clipboard_request}

      @selection = Gtk::Clipboard.get(Gdk::Selection::CLIPBOARD)
      @primary   = Gtk::Clipboard.get(Gdk::Selection::PRIMARY)

      mm = program.mini_menu
      mm.append_menu_item(:l!){ cbt.set_active(0) }
      mm.append_menu_item(:m!){ cbt.set_active(1) }
      mm.append_menu_item(:h!){ cbt.set_active(2) }

      @window.show_all
    end

    def clipboard_request
      text = @selection.wait_for_text
      unless @clipboard == text
        @clipboard = text
        if @url_match =~ text
          @auto = !@window.visible?
          @url.active_Entry.text = preprocess(text)
          @url.click_Button.clicked if @auto
        end
      end
      true
    end

    def preprocess(url)
      if @auto
        if CGI.unescape(url) =~ /(https?:\/\/www.youtube.com\/watch\?v=[^&]*)/
          url = $1
        end
      end
      url
    end

    def waiting?(thread)
      if thread or @download_thread or @playit_thread
        @error.text = CONFIG[:Wait]
        return true
      end
      return false
    end

    def doit
      if waiting? @doit_thread
        @cancel = true if @doit_thread and QuestionDialog.new(CONFIG[:Cancel], @window).runs
        return
      end
      @doit_thread = Rafini.thread_bang! do
        @scroll.destroy if @scroll
        @scroll = Such::ScrolledWindow.new @vbox, :expansive, :scroll!
        @records = Such::Box.new @scroll, :vbox!
        @error.text = CONFIG[:Running]
        @icon.set_pixbuf @downloading if @auto
        number = 0
        each_video do |obj|
          number += 1
          record(obj, number)
          @scroll.show_all
          @scroll.queue_draw
          Thread.pass
          break if number >= CONFIG[:Max]
        end
        if @auto
          # There were not videos and auto was never turned off.
          @auto = false
          @icon.set_pixbuf @ready
        end
        @cancel = false
        @error.text = CONFIG[:Done]
        @doit_thread = nil
      end
    end

    def each_video
      url = @url.active_Entry.text.strip
      if @url_match =~ url
        @mode = :url
        each_video_from_url(url){|obj|yield obj}
      else
        @mode = :search
        Mplay.videos_from_search(url).each{|obj|yield obj}
      end
    end

    def reload?(cache)
      @reload.active? or not File.exist?(cache)
    end

    def each_video_from_url(url)
      # May we just use the cache?
      cache = Mplay.db url
      unless reload?(cache)
        records = JSON.parse(File.read(cache))
        unless auto_reload?(cache, records)
          records.each{|obj|yield obj}
          return
        end
      end
      # No? Ok then...
      list = []
      Helpema::YouTubeDL.json(url) do |obj|
        case obj
        when String
          @error.text = obj
        when Hash
          list.push obj
          yield obj
        else
          # This would most likely be a bug.
          @error.text = "Got unexpected #{object.class} object."
        end
        break if @cancel
      end
      if list.length > 0 and not @cancel
        File.open(cache, 'w'){|f| f.puts JSON.pretty_generate list}
      end
    end

    def auto_reload?(cache, records)
      @auto and Mplay.expired?(cache) and not Mplay.cached_video?(records.first)
    end

    def augment(format,host,id)
      fid, ext = format.maps('format_id', 'ext')
      cache = Mplay.vd(host, id, fid, ext)
      format[:CACHE] = cache
      format[:CACHED] = File.exist?(cache)
    end

    def record(obj, number)
      window_title(obj) if number == 1
      title = (_=obj.keys.which{|k|CONFIG[:TITLE].include?(k)})? obj[_] : CONFIG[:NoTitle]
      $stderr.puts title if $VERBOSE
      Such::Label.new @records, ["#{number}. #{title}"], :title_label!
      info_label(obj)
      cache = dlbtn = nil
      host, id = Mplay.host_and_id(obj)
      if formats = obj['formats']
        formats.each{|format|augment(format,host,id)}
        formats.sort!{|a,b|fitness(b)<=>fitness(a)}
        combo = Combo.new(@records, :hbox!) do |_, signal|
          url, cache = combo.selects(formats).maps('url', :CACHE)
          case signal
          when 'clicked'
            playit(url, cache, combo, dlbtn)
          when 'changed'
            dlbtn.relabel(cache)
          end
        end
        combo.appends formats.map{|a|a['format']}
        dlbtn = DownloadButton.new combo, :click! do
          if File.exist? cache
            export_file(cache, dlbtn)
          else
            url = combo.selects(formats)['url']
            downloadit(url, cache, combo, dlbtn)
          end
        end
        if webpage_url = obj['webpage_url']
          Such::Button.new combo, [label: CONFIG[:WebPage]], :click!, 'button-press-event' do |*event, signal|
            case signal
            when 'button-press-event' # Just doing this event
              case event.last.button
              when 1
                system "#{Gtk3App::CONFIG[:Open]} '#{webpage_url}'"
                true
              when 2
                @primary.text = webpage_url
                true
              when 3
                @selection.text = webpage_url
                true
              end
            end
          end
        end
        combo.labels(*CONFIG[:COMBO_LABELS])
        if @auto
          @auto = false # Just on the most likely format
          @icon.set_pixbuf @playing
          # Clear the clipboard
          @selection.text = @clipboard = ''
          combo.click_Button.clicked
        end
      end
    end

    def export_file(cache, dlbtn)
      if cache == @download_cache
        @error.text = CONFIG[:Wait]
        return
      end
      if export = ExportDialog.new(@window, File.basename(cache)).runs
        begin
          FileUtils.ln cache, export
          @error.text = CONFIG[:Ln]
        rescue StandardError
          begin
            $!.puts
            FileUtils.cp cache, export
            @error.text = CONFIG[:Cp]
          rescue StandardError
            $!.puts
            @error.text $!.message
            dlbtn.override_color :normal, @red
          end
        end
      end
    end

    def window_title(obj)
      if @mode==:url and title = obj['playlist_title']
        @window.set_title title
      else
        @window.set_title CONFIG[:thing][:window][:set_title]
      end
    end

    def info_label(obj)
      label = Mplay.info(obj)
      if label.length > 1
        _ = Such::Label.new @records, [label], :title_label!
        _.override_font @small_font
      end
    end

    def playit(url, cache, combo, dlbtn)
      btn = combo.click_Button
      if File.exist?(cache)
        btn.override_color :normal, @blue
        Mplay.mplayer(cache)
        @icon.set_pixbuf @ready
      else
        return if waiting? @playit_thread
        btn.override_color :normal, @blue
        @download_cache = cache
        @playit_thread = Rafini.thread_bang! do
          btn.set_sensitive false
          dlbtn.set_sensitive false
          @error.text = CONFIG[:Running]
          if Mplay.tee(url, cache)
            dlbtn.relabel(cache)
          else
            btn.override_color :normal, @red
          end
          @error.text = CONFIG[:Done]
          @icon.set_pixbuf @ready
          @download_cache = @playit_thread = nil
          btn.set_sensitive true
          dlbtn.set_sensitive true
        end
      end
    end

    def downloadit(url, cache, combo, dlbtn)
      return if waiting? @download_thread
      btn = combo.click_Button
      @download_cache = cache
      @download_thread = Rafini.thread_bang! do
        dlbtn.set_sensitive false
        @error.text = CONFIG[:Running]
        btn.override_color :normal, @blue
        if Mplay.wget(url, cache)
          dlbtn.relabel(cache)
        else
          btn.override_color :normal, @red
        end
        @error.text = CONFIG[:Done]
        @download_cache = @download_thread = nil
        dlbtn.set_sensitive true
      end
    end
  end
end
