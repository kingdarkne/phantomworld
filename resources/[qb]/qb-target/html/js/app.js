function FadeIn(Object, Timeout) {
  $(Object).fadeIn(Timeout).css('display', 'block');
}

function FadeOut(Object, Timeout) {
  $(Object).fadeOut(Timeout);
  setTimeout(function () {
    $(Object).css('display', 'none');
  }, Timeout);
}

const Targeting = Vue.createApp({
  data() {
    return {
      Show: false,
      ChangeTextIconColor: false, // This is if you want to change the color of the icon next to the option text with the text color
      StandardEyeIcon: 'https://img-puhutv.mncdn.com/media/img/content/23-01/26/ntv.png', // Instead of icon it's using a image source found in HTML
      CurrentIcon: 'https://img-puhutv.mncdn.com/media/img/content/23-01/26/ntv.png', // Instead of icon it's using a image source found in HTML
      SuccessIcon: 'https://img-puhutv.mncdn.com/media/img/content/23-01/26/ntv.png', // Instead of icon it's using a image source found in HTML
      SuccessColor: '#2baf90cb;',
      StandardColor: 'white',
      TargetHTML: '',
      TargetEyeStyleObject: {
        color: 'white', // This is the standardcolor, change this to the same as the StandardColor if you have changed it
      },
    };
  },
  destroyed() {
    window.removeEventListener('message', this.messageListener);
    window.removeEventListener('mousedown', this.mouseListener);
    window.removeEventListener('keydown', this.keyListener);
  },
  mounted() {
    this.messageListener = window.addEventListener('message', (event) => {
      switch (event.data.response) {
        case 'opencircle':
          let xx = event.data.post;
          OpenCircle(xx.x, xx.y, xx.id);
          break;
        case 'closecircle':
          FadeOut('#circle-' + event.data.post.id, 200);
          break;
        case 'updatecircle':
          $('#circle-' + event.data.post.id).css('left', event.data.post.x * 100 + '%');
          $('#circle-' + event.data.post.id).css('right', 100 - event.data.post.x * 100 + '%');
          $('#circle-' + event.data.post.id).css('top', event.data.post.y * 100 + '%');
          $('#circle-' + event.data.post.id).css('bottom', 100 - event.data.post.y * 100 + '%');
          break;
        case 'openTarget':
          this.OpenTarget();
          break;
        case 'closeTarget':
          this.CloseTarget();
          break;
        case 'foundTarget':
          $('.ana').css('filter', 'drop-shadow(0vw 0vw .4vw #f3c955be)');
          $('.ana img').css('filter', 'drop-shadow(0vw 0vw .4vw #f3c955be)');
          $('#target-eye').css('filter', 'drop-shadow(0vw 0vw .3vw #f3c955be)');
          $('.alt img').css('top', '52.7vh');
          $('.alt img').css('opacity', '0.55');
          this.FoundTarget(event.data);
          break;
        case 'validTarget':
          this.ValidTarget(event.data);
          break;
        case 'leftTarget':
          $('.ana').css('filter', 'drop-shadow(0vw 0vw 0.0vw #f3c955be)');
          $('.ana img').css('filter', 'drop-shadow(0vw 0vw 0.0vw #f3c955be)');
          $('#target-eye').css('filter', 'drop-shadow(0vw 0vw .2vw #ffe572d0');
          $('.alt img').css('top', '51.7vh');
          $('.alt img').css('opacity', '0.0');
          this.LeftTarget();
          break;
      }
    });

    this.mouseListener = window.addEventListener('mousedown', (event) => {
      let element = event.target;
      let split = element.id.split('-');
      if (split[0] === 'target' && split[1] !== 'eye') {
        $.post(`https://qb-target/selectTarget`, JSON.stringify(Number(split[1]) + 1));
        this.TargetHTML = '';
        this.Show = false;
      }

      if (event.button == 2) {
        this.CloseTarget();
        $.post(`https://qb-target/closeTarget`);
      }
    });

    this.keyListener = window.addEventListener('keydown', (event) => {
      if (event.key == 'Escape' || event.key == 'Backspace') {
        this.CloseTarget();
        $.post(`https://qb-target/closeTarget`);
      }
    });
  },
  methods: {
    OpenTarget() {
      this.TargetHTML = '';
      this.Show = true;
      this.TargetEyeStyleObject.color = this.StandardColor;
    },

    CloseTarget() {
      this.TargetHTML = '';
      this.TargetEyeStyleObject.color = this.StandardColor;
      this.Show = false;
    },

    FoundTarget(item) {
      if (item.data) {
        this.CurrentIcon = item.data;
      } else {
        this.CurrentIcon = this.SuccessIcon;
      }
      this.TargetEyeStyleObject.color = this.SuccessColor;
    },

    ValidTarget(item) {
      this.TargetHTML = '';
      let TargetLabel = this.TargetHTML;
      const FoundColor = this.SuccessColor;
      const ResetColor = this.StandardColor;
      const AlsoChangeTextIconColor = this.ChangeTextIconColor;
      item.data.forEach(function (item, index) {
        if (AlsoChangeTextIconColor) {
          TargetLabel +=
            "<div style='margin: 0.1vw; padding-top: 8px; padding-bottom: 6px; padding-right: 9px; padding-left: 1px; transition: all 0.3s; border: 1px solid #10cca000; border-radius: 0.1267vw; background: linear-gradient(to bottom, #b996375e 30% , #b996375e 60% , #b996375e 100%);' id='target-" +
            index +
            "' style='margin-bottom: 1vh;'><span id='target-icon-" +
            index +
            "' style='color: " +
            ResetColor +
            "'><i style='margin-left: .35vw; margin-right: .30vw;  font-size: 1.3vh; color: #ffe572;' class='" +
            item.icon +
            "'></i></span>&nbsp" +
            item.label +
            '</div>';
        } else {
          TargetLabel +=
            "<div style='margin: 0.1vw; padding-top: 8px; padding-bottom: 6px; padding-right: 9px; padding-left: 1px; transition: all 0.3s; border: 1px solid #10cca000; border-radius: 0.1267vw; background: linear-gradient(to bottom, #b996375e 30% , #b996375e 60% , #b996375e 100%);' id='target-" +
            index +
            "' style='margin-bottom: 1vh;'><span id='target-icon-" +
            index +
            "' style='color: " +
            FoundColor +
            "'><i style='margin-left: .35vw; margin-right: .30vw;  font-size: 1.3vh; color: #ffe572;' class='" +
            item.icon +
            "'></i></span>&nbsp" +
            item.label +
            '</div>';
        }

        setTimeout(function () {
          const hoverelem = document.getElementById('target-' + index);
          if (!hoverelem) {
            return;
          }

          hoverelem.addEventListener('mouseenter', function (event) {
            event.target.style =
              'cursor: pointer; margin: 0.1vw; padding-top: 8px; padding-bottom: 6px; padding-right: 9px; border: 1px solid #ffe572; padding-left: 1px; transition: all 0.3s;  border-radius: 0.1267vw; background: linear-gradient(to bottom, #ffd15275 10% , #ffd15275 50% , #ffd15275 100%);';
          });

          hoverelem.addEventListener('mouseleave', function (event) {
            event.target.style =
              'cursor: pointer; margin: 0.1vw; padding-top: 8px; padding-bottom: 6px; padding-right: 9px; padding-left: 1px; transition: all 0.3s; border: 1px solid #10cca000; border-radius: 0.1267vw; background: linear-gradient(to bottom, #b996375e 30% , #b996375e 60% , #b996375e 100%);';
          });
        }, 10);
      });
      this.TargetHTML = TargetLabel;
    },

    LeftTarget() {
      this.TargetHTML = '';
      this.CurrentIcon = this.StandardEyeIcon;
      this.TargetEyeStyleObject.color = this.StandardColor;
    },
  },
});

Targeting.use(Quasar, {
  config: {
    loadingBar: { skipHijack: true },
  },
});
Targeting.mount('#target-wrapper');

function OpenCircle(x, y, id) {
  $('.circle').append(`
        <img id="circle-${id}" style="display: none; top: 25vw; left: 50vw; position: absolute; width: 30px; height: 30px;" src="css/circle.svg" alt="">
    `);
  $('#circle-' + id).css('left', x * 100 + '%');
  $('#circle-' + id).css('right', 100 - x * 100 + '%');
  $('#circle-' + id).css('top', y * 100 + '%');
  $('#circle-' + id).css('bottom', 100 - y * 100 + '%');
  FadeIn('#circle-' + id, 200);
}
