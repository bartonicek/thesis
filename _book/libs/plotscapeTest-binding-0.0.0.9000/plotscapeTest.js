HTMLWidgets.widget({

  name: 'plotscapeTest',
  type: 'output',

  factory: function(el, width, height) {

    // TODO: define shared variables for this instance

    return {

      renderValue: function(x) {

        console.log(x)

        // TODO: code to render the widget, e.g.
        el.classList.add("graphicDiv")
        const scene = new PLOTSCAPE.Scene(el, new PLOTSCAPE.DataFrame(x.data),
                                          {layout : x.layout})

        if (!x.types) return
        const typeArray = Array.isArray(x.types) ? x.types : [x.types]
        typeArray.forEach((e, i) => {
          const mapping = x.mappings[i]
          const mappingArray = Object.keys(mapping).map(e => [e, mapping[e]])
          scene.addPlotWrapper(e, new PLOTSCAPE.Mapping(...mappingArray))
        })

      },

      resize: function(width, height) {

        // TODO: code to re-render the widget with a new size

      }

    };
  }
});
