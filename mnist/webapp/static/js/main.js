var app = new Vue({
    delimiters:['${', '}'],
    el: '#app',
    data: {
        debug_only: false,
        instructions: "Click on an image and press submit",
        product: 'MNIST on Kubeflow',
        image: './static/data/0.png',
        image_to_be_identified: 'none',
        inferred_digit: 'none',
        show: true,
        imagelist: ['./static/data/0.png',
                    './static/data/1.png',
                    './static/data/2.png',
                    './static/data/3.png',
                    './static/data/4.png',
                    './static/data/5.png',
                    './static/data/6.png',
                    './static/data/7.png',
                    './static/data/8.png',
                    './static/data/9.png']
    },
    methods: {
        call_inference: function (image) {
            this.image_to_be_identified = image
        },
        submit: function () {
            //this.inferred_digit = "inferring for " + this.image_to_be_identified + "...",
            this.show = false,
            setTimeout(() => this.show = true, 5000)

            $.ajax({
                  context: this,
                  type: "POST",
                  url: "/predict",
                  data : { img : this.image_to_be_identified },
                  // handle success
                  success: function(result) {
                    this.inferred_digit = result
                    console.log("result"+result);
                  },
                  // handle error
                  error: function(error) {
                    console.log("Error "+error);
                  }
             });
        }
    }
})

