import { Component, OnInit, OnDestroy } from '@angular/core';
import * as Rellax from 'rellax';

@Component({
  selector: 'app-landing',
  templateUrl: './services.component.html',
  styleUrls: ['./services.component.scss']
})
export class ServicesComponent implements OnInit {
    data : Date = new Date();

  constructor() { }

  ngOnInit() {
    var rellaxHeader = new Rellax('.rellax-header');
    var navbar = document.getElementsByTagName('nav')[0];
    navbar.classList.add('navbar-transparent');
    var body = document.getElementsByTagName('body')[0];
    body.classList.add('landing-page');
  }
  ngOnDestroy(){
    var navbar = document.getElementsByTagName('nav')[0];
    navbar.classList.remove('navbar-transparent');
    var body = document.getElementsByTagName('body')[0];
    body.classList.remove('landing-page');
  }
}
