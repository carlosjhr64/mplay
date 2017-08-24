Such::Parts.make('LabelEntryButton', 'Box', :prompt_Label, :active_Entry, :click_Button)
Such::Parts.make('LabelComboButton', 'Box', :prompt_Label, :combo_ComboBoxText, :click_Button)

module Such

  class LabelEntryButton
    def labels(*vars)
      a, b, c = *vars
      [
        a ? (prompt_Label.text=a)  : prompt_Label.text,
        b ? (active_Entry.text=b)  : active_Entry.text,
        c ? (click_Button.label=c) : click_Button.label
      ]
    end
  end

  class LabelComboButton
    def labels(*vars)
      a, b, c = *vars
      [
        a ? (prompt_Label.text=a)              : prompt_Label.text,
        b ? (combo_ComboBoxText.set_active(b)) : combo_ComboBoxtText.active,
        c ? (click_Button.label=c)             : click_Button.label
      ]
    end
  end

end
