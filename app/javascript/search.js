$(document).on("turbolinks:load", function(){
  $('#portal-search-bar').on('keydown', function(e){
    if(e.which == 13) {
      let text_content = $('#portal-search-bar').val();
      let selecteditems = [];
      $("#portal-search-list").find("input:checked").each(function (i, ob) { 
          selecteditems.push($(ob).val());
      });

      $.ajax({
        url: `/portals/search/${selecteditems}/${text_content}`,
        method: 'post',
        dataType: 'script',
        success: function(data) { 
          addqueryresultToPortal()
        }
      })
    }

    if(e.which == 27) {
      $('#portal-search-bar').val("")
    }
  })

  $('input[type=radio][name=portal-search-radio]').on('change', function() {
    let text_content = $('#portal-search-bar').val();

    $.ajax({
      url: `/portals/search/${this.value}/${text_content}`,
      method: 'post',
      dataType: 'script',
      success: function(data) { 
        addqueryresultToPortal()
      }
    })
  });

  $('.fa-portal-search').on('click', function(){
    let text_content = $('#portal-search-bar').val();
    let selecteditems = [];
    $("#portal-search-list").find("input:checked").each(function (i, ob) { 
      selecteditems.push($(ob).val());
    });

    $.ajax({
      url: `/portals/search/${selecteditems}/${text_content}`,
      method: 'post',
      dataType: 'script',
      success: function(data) { 
        addqueryresultToPortal()
      }
    })
  })
})

function addqueryresultToPortal() {
  $(".portal-search-result").on('click', function(){
    let portalId = this.dataset["portalId"];

    if ($(`[data-norepeat-portal-id="${portalId}"]`).length < 1){
      $.ajax({
        url: '/portals/find_devices/' + portalId,
        method: 'get',
        dataType: 'script',
      })
      $(this).remove();
    } else{
      Swal.fire("portal_id repeat!", "", "error")
    }
  })
}
